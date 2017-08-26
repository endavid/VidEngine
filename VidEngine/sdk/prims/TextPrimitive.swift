//
//  TextPrimitive.swift
//  VidEngine
//
//  Created by David Gavilan on 2017/05/29.
//  Swift port of http://metalbyexample.com/rendering-text-in-metal-with-signed-distance-fields/
//

import MetalKit

struct CFArrayEx<Element> : Collection, RandomAccessCollection {
    typealias Index = Int

    private let ref : CFArray

    init(ref: CFArray) {
        self.ref = ref
    }

    var startIndex : Index {
        return 0
    }

    var endIndex: Index {
        return CFArrayGetCount(ref)
    }

    subscript(index: Index) -> Element {
        return unsafeBitCast(CFArrayGetValueAtIndex(ref, index), to: Element.self)
    }

    func index(after i: Index) -> Index {
        return i + 1
    }

    func index(before i: Index) -> Index {
        return i - 1
    }
}

extension CFArrayEx where Element == CTLine {
    func glyphCount() -> Int {
        return lazy.map { $0.glyphCount }.sum()
    }

    init(frame : CTFrame) {
        self.init(ref : CTFrameGetLines(frame))
    }
}

extension CTLine {
    var glyphCount : Int {
        return CTLineGetGlyphCount(self)
    }

    var runs : CFArrayEx<CTRun> {
        return CFArrayEx(ref: CTLineGetGlyphRuns(self))
    }
}

extension CTRun {
    var glyphCount : Int {
        return CTRunGetGlyphCount(self)
    }

    var glyphs: [CGGlyph] {
        var ret = [CGGlyph](repeating: CGGlyph(), count: glyphCount)
        CTRunGetGlyphs(self, CFRange(), &ret)
        return ret
    }

    var positions : [CGPoint] {
        var ret = [CGPoint](repeating: CGPoint(), count: glyphCount)
        CTRunGetPositions(self, CFRange(), &ret)
        return ret
    }

    func imageBounds(ctx: CGContext, idx: Int) -> CGRect {
        return CTRunGetImageBounds(self, ctx, CFRange(location: idx, length: 1))
    }
}

extension Sequence where Iterator.Element : IntegerArithmetic & ExpressibleByIntegerLiteral {
    func sum() -> Iterator.Element {
        return reduce(0, +)
    }
}

/// Text is rendered with a quad per glyph, using a `FontAtlas`
public class TextPrimitive : Primitive {
    
    public init(numInstances: Int, font: FontAtlas, text: String, fontSizeMeters: Float, enclosingFrame: CGRect) {
        super.init(numInstances: numInstances)
        self.lightingType = .UnlitTransparent
        buildMeshWithString(text: text, rect: enclosingFrame, fontAtlas: font, fontSize: CGFloat(fontSizeMeters))
    }
    
    private func buildMeshWithString(text: String, rect: CGRect, fontAtlas: FontAtlas, fontSize: CGFloat) {
        let font = fontAtlas.parentFont.withSize(fontSize)
        let attrString = NSAttributedString(string: text, attributes: [NSFontAttributeName: font])
        let stringRange = CFRangeMake(0, attrString.length)
        let rectPath = CGPath(rect: rect, transform: nil)
        let frameSetter = CTFramesetterCreateWithAttributedString(attrString)
        let frame = CTFramesetterCreateFrame(frameSetter, stringRange, rectPath, nil)

        let lines = CFArrayEx(frame: frame)
        let frameGlyphCount = lines.glyphCount()

        let vertexCount = frameGlyphCount * 4
        let indexCount = frameGlyphCount * 6
        var indices = [UInt16](repeating: 0, count: indexCount)
        vertexBuffer = RenderManager.sharedInstance.createTexturedVertexBuffer("Text VB", numElements: vertexCount)
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
        let indexBuffer = RenderManager.sharedInstance.createIndexBuffer("Text IB", elements: indices)
        submeshes.append(Mesh(numIndices: index, indexBuffer: indexBuffer, albedoTexture: fontAtlas.fontTexture))
    }

    private func enumerateGlyphsInFrame(frame: CTFrame, callback: (CGGlyph, Int, CGRect) -> ()) {
        let framePath = CTFrameGetPath(frame)
        let frameBoundingRect = framePath.boundingBox
        let lines = CFArrayEx(frame: frame)

        var lineOriginArray = [CGPoint](repeating: CGPoint(), count: lines.count)
        CTFrameGetLineOrigins(frame, CFRange(), &lineOriginArray)
        var glyphIndexInFrame = 0
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        let context = UIGraphicsGetCurrentContext()
        for (line, lineOrigin) in zip(lines, lineOriginArray) {
            for run in line.runs {
                var glyphArray = run.glyphs
                var positionArray = run.positions

                for glyphIndex in 0..<run.glyphCount {
                    let glyph = glyphArray[glyphIndex]
                    let glyphOrigin = positionArray[glyphIndex]

                    let boundsTransX = frameBoundingRect.origin.x + lineOrigin.x
                    let boundsTransY = frameBoundingRect.height + frameBoundingRect.origin.y - lineOrigin.y + glyphOrigin.y
                    let pathTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: boundsTransX, ty: boundsTransY)

                    let glyphRect = run.imageBounds(ctx: context!, idx: glyphIndex).applying(pathTransform)

                    callback(glyph, glyphIndexInFrame, glyphRect)
                    glyphIndexInFrame += 1
                }
            }
        }
        UIGraphicsEndImageContext()
    }
}
