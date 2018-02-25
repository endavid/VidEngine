//
//  Primitive2DPlugin.swift
//  VidEngine
//
//  Created by David Gavilan on 10/9/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

class Primitive2DPlugin : GraphicPlugin {
    let maxNumSprites = 2000
    fileprivate var sprites : [SpritePrimitive2D] = []
    fileprivate var bounds = CGRect()
    fileprivate var pipelineState: MTLRenderPipelineState! = nil
    fileprivate var spriteVB : MTLBuffer! = nil
    fileprivate var spriteIB : MTLBuffer! = nil
    fileprivate var spriteVBoffset = 0

    func queue(_ primitive: Primitive2D) {
        if let sprite = primitive as? SpritePrimitive2D {
            let alreadyQueued = sprites.contains { $0 === sprite }
            if !alreadyQueued {
                // @todo insert in priority order, with binary search
                sprites.append(sprite)
            }
        }
    }
    func dequeue(_ primitive: Primitive2D) {
        if let sprite = primitive as? SpritePrimitive2D {
            let index = sprites.index { $0 === sprite }
            if let i = index {
                sprites.remove(at: i)
            }
        }
    }
    override init(device: MTLDevice, library: MTLLibrary, view: MTKView) {
        super.init(device: device, library: library, view: view)
        
        let fragmentProgram = library.makeFunction(name: "passThroughTexturedFragment")!
        let vertexProgram = library.makeFunction(name: "passSprite2DVertex")!
        
        // check ColoredUnlitTexturedVertex
        let vertexDesc = MTLVertexDescriptor()
        vertexDesc.attributes[0].format = .float3
        vertexDesc.attributes[0].offset = 0
        vertexDesc.attributes[0].bufferIndex = 0
        vertexDesc.attributes[1].format = .float2
        vertexDesc.attributes[1].offset = MemoryLayout<Vec3>.size
        vertexDesc.attributes[1].bufferIndex = 0
        vertexDesc.attributes[2].format = .uchar4Normalized
        vertexDesc.attributes[2].offset = MemoryLayout<Vec3>.size + MemoryLayout<Vec2>.size
        vertexDesc.attributes[2].bufferIndex = 0
        vertexDesc.layouts[0].stepFunction = .perVertex
        vertexDesc.layouts[0].stride = MemoryLayout<ColoredUnlitTexturedVertex>.size
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.vertexDescriptor = vertexDesc
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.sampleCount = view.sampleCount
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
        // generate a large enough buffer to allow streaming vertices for 3 semaphore controlled frames
        // 4 vertices per sprite * max * triple buffer
        spriteVB = device.makeBuffer(length: Renderer.NumSyncBuffers * maxNumSprites * MemoryLayout<ColoredUnlitTexturedVertex>.size * 4, options: [])
        // we don't need to triple buffer this because it's going to be static
        // 6 indices per sprite
        spriteIB = device.makeBuffer(length: maxNumSprites * MemoryLayout<UInt16>.size * 6, options: [])
        initSpriteIndexBuffer()
    }
    override func draw(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer, camera: Camera) {
        bounds = camera.bounds
        if sprites.count > 0 {
            let whiteTexture = Renderer.shared.whiteTexture
            let renderPassDescriptor = Renderer.shared.createRenderPassWithColorAttachmentTexture(drawable.texture, clear: false)
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            encoder?.label = "Primitive2D Encoder"
            encoder?.pushDebugGroup("primitive2d")
            encoder?.setRenderPipelineState(pipelineState)
            encoder?.setFragmentTexture(whiteTexture, index: 0)
            encoder?.setVertexBuffer(spriteVB, offset: spriteVBoffset, index: 0)
            encoder?.drawIndexedPrimitives(type: .triangle, indexCount: sprites.count * 6, indexType: .uint16, indexBuffer: spriteIB, indexBufferOffset: 0)
            encoder?.popDebugGroup()
            encoder?.endEncoding()
        }
    }
    override func updateBuffers(_ syncBufferIndex: Int) {
        spriteVBoffset = MemoryLayout<ColoredUnlitTexturedVertex>.size * maxNumSprites * 4 * syncBufferIndex
        updateSpriteBuffer()
    }
    
    private func initSpriteIndexBuffer() {
        let ib = spriteIB.contents().advanced(by: 0).assumingMemoryBound(to: UInt16.self)
        for i in 0..<maxNumSprites {
            ib[6*i]   = UInt16(4*i)
            ib[6*i+1] = UInt16(4*i+2)
            ib[6*i+2] = UInt16(4*i+1)
            ib[6*i+3] = UInt16(4*i+3)
            ib[6*i+4] = UInt16(4*i+2)
            ib[6*i+5] = UInt16(4*i+1)
        }
    }
    
    private func updateSpriteBuffer() {
        let vb = spriteVB.contents().advanced(by: spriteVBoffset).assumingMemoryBound(to: ColoredUnlitTexturedVertex.self)
        let sx = 2 / Float(bounds.width)
        let sy = 2 / Float(bounds.height)
        for i in 0..<sprites.count {
            // expand vertices of sprites
            let sprite = sprites[i]
            let w = sprite.width
            let h = sprite.height
            var tx : Float = 0
            var ty : Float = 0
            if sprite.options.contains(.alignCenter) {
                tx = -0.5 * w
                ty = -0.5 * h
            } else if sprite.options.contains(.alignBottom) {
                tx = -sprite.width
            } else {
                ty = -sprite.height
            }
            var vertices = [
                Vec3(tx, ty, 0),
                Vec3(tx, ty + h, 0),
                Vec3(tx + w, ty, 0),
                Vec3(tx + w, ty + h, 0)
            ]
            if sprite.options.contains(.allowRotation) {
                let cosa = sprite.cosa
                let sina = sprite.sina
                for k in 0..<vertices.count {
                    let x = vertices[k].x
                    let y = vertices[k].y
                    vertices[k] = Vec3(
                        sx * (cosa * x - sina * y),
                        sy * (sina * x + cosa * y), 0)
                }
            } else {
                for k in 0..<vertices.count {
                    let x = vertices[k].x
                    let y = vertices[k].y
                    vertices[k] = Vec3(x * sx, y * sy, 0)
                }
            }
            // @todo set UV from texture atlas
            let u0 : Float = 0
            let u1 : Float = 1
            let v0 : Float = 0
            let v1 : Float = 1
            vb[4*i+0].position = sprite.position + vertices[0]
            vb[4*i+1].position = sprite.position + vertices[1]
            vb[4*i+2].position = sprite.position + vertices[2]
            vb[4*i+3].position = sprite.position + vertices[3]
            vb[4*i+0].uv = Vec2(u0, v0)
            vb[4*i+1].uv = Vec2(u0, v1)
            vb[4*i+2].uv = Vec2(u1, v0)
            vb[4*i+3].uv = Vec2(u1, v1)
            vb[4*i+0].color = sprite.color.rgba
            vb[4*i+1].color = sprite.color.rgba
            vb[4*i+2].color = sprite.color.rgba
            vb[4*i+3].color = sprite.color.rgba
        } // for all sprites
    } // updateSpriteBuffer
}
