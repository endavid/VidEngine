//
//  TextPrimitive.swift
//  VidEngine
//
//  Created by David Gavilan on 2017/05/29.
//  Swift port of http://metalbyexample.com/rendering-text-in-metal-with-signed-distance-fields/
//

import Metal
import MetalKit

/// Text is rendered with a quad per glyph, using a `FontAtlas`
public class TextPrimitive : Primitive {
    let fontAtlas: FontAtlas
    let text: String
    let fontSizeMeters: Float
    let enclosingFrame: CGRect
    
    public init(instanceCount: Int, font: FontAtlas, text: String, fontSizeMeters: Float, enclosingFrame: CGRect) {
        self.fontAtlas = font
        self.text = text
        self.fontSizeMeters = fontSizeMeters
        self.enclosingFrame = enclosingFrame
        super.init(instanceCount: instanceCount)
        self.lightingType = .unlitTransparent
        submeshes.append(Mesh())
    }
    
    override func initBuffers(_ renderer: Renderer) {
        super.initBuffers(renderer)
        fontAtlas.initTexture(renderer)
        if vertexBuffer == nil {
            buildMeshWithString(renderer: renderer, text: text, rect: enclosingFrame, fontAtlas: fontAtlas, fontSize: CGFloat(fontSizeMeters))
        }
    }
    
    private func buildMeshWithString(renderer: Renderer, text: String, rect: CGRect, fontAtlas: FontAtlas, fontSize: CGFloat) {
        let font = fontAtlas.parentFont.withSize(fontSize)
        let attrString = NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: font])
        let stringRange = CFRangeMake(0, attrString.length)
        let rectPath = CGPath(rect: rect, transform: nil)
        let frameSetter = CTFramesetterCreateWithAttributedString(attrString)
        let frame = CTFramesetterCreateFrame(frameSetter, stringRange, rectPath, nil)
        var frameGlyphCount = 0
        let lines = CTFrameGetLines(frame)
        let numLines = CFArrayGetCount(lines)
        for i in 0..<numLines {
            let lineObject = CFArrayGetValueAtIndex(lines, i)
            let line = unsafeBitCast(lineObject, to: CTLine.self)
            frameGlyphCount += CTLineGetGlyphCount(line)
        }
        let vertexCount = frameGlyphCount * 4
        let indexCount = frameGlyphCount * 6
        var indices = [UInt16](repeating: 0, count: indexCount)
        let vertexBuffer = renderer.createTexturedVertexBuffer("Text VB", numElements: vertexCount)
        self.vertexBuffer = vertexBuffer
        let vb = vertexBuffer.contents().assumingMemoryBound(to: TexturedVertex.self)
        var index = 0
        var vertex = 0
        let up = Vec3(0, 1, 0)
        enumerateGlyphsInFrame(frame: frame) { (glyph: CGGlyph, glyphIndex: Int, glyphBounds: CGRect) in
            let fontIndex = Int(glyph)
            if (fontIndex >= fontAtlas.glyphs.count) {
                NSLog("Font atlas has no entry corresponding to glyph \(glyphIndex)")
                return
            }
            let glyphInfo = fontAtlas.glyphs[fontIndex]
            let minX = Float(glyphBounds.minX)
            let maxX = Float(glyphBounds.maxX)
            let minY = Float(glyphBounds.minY)
            let maxY = Float(glyphBounds.maxY)
            let minS = Float(glyphInfo.topLeftTexCoord.x)
            let maxS = Float(glyphInfo.bottomRightTexCoord.x)
            let minT = Float(glyphInfo.topLeftTexCoord.y)
            let maxT = Float(glyphInfo.bottomRightTexCoord.y)
            // follow the convention of PlanePrimitive and place the characters on the ground
            vb[vertex] = TexturedVertex(position: Vec3(minX, 0, maxY), normal: up, uv: Vec2(minS, maxT))
            vb[vertex+1] = TexturedVertex(position: Vec3(minX, 0, minY), normal: up, uv: Vec2(minS, minT))
            vb[vertex+2] = TexturedVertex(position: Vec3(maxX, 0, minY), normal: up, uv: Vec2(maxS, minT))
            vb[vertex+3] = TexturedVertex(position: Vec3(maxX, 0, maxY), normal: up, uv: Vec2(maxS, maxT))
            vertex += 4
            let gi4 = UInt16(glyphIndex * 4)
            indices[index] = gi4 + 1
            indices[index+1] = gi4
            indices[index+2] = gi4 + 2
            indices[index+3] = gi4 + 3
            indices[index+4] = gi4 + 2
            indices[index+5] = gi4
            index += 6
        }
        let indexBuffer = renderer.createIndexBuffer("Text IB", elements: indices)
        do {
            let fontTexture = try fontAtlas.getFontTexture(renderer)
            submeshes[0].numIndices = index
            submeshes[0].indexBuffer = indexBuffer
            submeshes[0].albedoTexture = fontTexture
            submeshes[0].sampler = .linearWithClamp
        } catch let error {
            NSLog("buildMeshWithString: \(error.localizedDescription)")
        }
    }
    
    private func enumerateGlyphsInFrame(frame: CTFrame, callback: (CGGlyph, Int, CGRect) -> ()) {
        let entire = CFRangeMake(0, 0)
        let framePath = CTFrameGetPath(frame)
        let frameBoundingRect = framePath.boundingBox
        let lines = CTFrameGetLines(frame)
        let numLines = CFArrayGetCount(lines)
        var lineOriginArray = [CGPoint](repeating: CGPoint(), count: numLines)
        CTFrameGetLineOrigins(frame, entire, &lineOriginArray)
        var glyphIndexInFrame = 0
        for i in 0..<numLines {
            let lineObject = CFArrayGetValueAtIndex(lines, i)
            let line = unsafeBitCast(lineObject, to: CTLine.self)
            let lineOrigin = lineOriginArray[i]
            let runs = CTLineGetGlyphRuns(line)
            let numRuns = CFArrayGetCount(runs)
            for j in 0..<numRuns {
                let runObject = CFArrayGetValueAtIndex(runs, j)
                let run = unsafeBitCast(runObject, to: CTRun.self)
                let glyphCount = CTRunGetGlyphCount(run)
                var glyphArray = [CGGlyph](repeating: CGGlyph(), count: glyphCount)
                CTRunGetGlyphs(run, entire, &glyphArray)
                var positionArray = [CGPoint](repeating: CGPoint(), count: glyphCount)
                CTRunGetPositions(run, entire, &positionArray)
                for glyphIndex in 0..<glyphCount {
                    let glyph = glyphArray[glyphIndex]
                    let glyphOrigin = positionArray[glyphIndex]
                    // the bounds are relative to CGPointZero if context is nil
                    var glyphRect = CTRunGetImageBounds(run, nil, CFRangeMake(glyphIndex, 1))
                    let boundsTransX = frameBoundingRect.origin.x + lineOrigin.x
                    let boundsTransY = frameBoundingRect.height + frameBoundingRect.origin.y - lineOrigin.y + glyphOrigin.y
                    let pathTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: boundsTransX, ty: boundsTransY)
                    glyphRect = glyphRect.applying(pathTransform)
                    callback(glyph, glyphIndexInFrame, glyphRect)
                    glyphIndexInFrame += 1
                }
            }
        }
    }
}
