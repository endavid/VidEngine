//
//  Primitive2DPlugin.swift
//  VidEngine
//
//  Created by David Gavilan on 10/9/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

class Primitive2DPlugin: GraphicPlugin {
    fileprivate var groups: [Group2D] = []
    fileprivate var pipelineState: MTLRenderPipelineState! = nil
    fileprivate var sRgbPipelineState: MTLRenderPipelineState! = nil

    func queue(_ group: Group2D) {
        let alreadyQueued = groups.contains { $0 === group }
        if !alreadyQueued {
            groups.append(group)
        }
    }
    func dequeue(_ group: Group2D) {
        let index = groups.index { $0 === group }
        if let i = index {
            groups.remove(at: i)
        }
    }
    override init(device: MTLDevice, library: MTLLibrary, view: MTKView) {
        super.init(device: device, library: library, view: view)
        
        let fp = library.makeFunction(name: "passThroughTexturedFragment")!
        let fpSrgb = library.makeFunction(name: "passThroughSrgbTexturedFragment")!
        let vp = library.makeFunction(name: "passSprite2DVertex")!
        
        let vertexDesc = createVertexDescriptor()
        let pipeDesc = createPipelineDescriptor(vp: vp, fp: fp, vertexDesc: vertexDesc, pixelFormat: view.colorPixelFormat, sampleCount: view.sampleCount)
        let sRgbPipeDesc = createPipelineDescriptor(vp: vp, fp: fpSrgb, vertexDesc: vertexDesc, pixelFormat: view.colorPixelFormat, sampleCount: view.sampleCount)
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipeDesc)
            try sRgbPipelineState = device.makeRenderPipelineState(descriptor: sRgbPipeDesc)
        } catch let error {
            NSLog("Failed to create pipeline state, error \(error)")
        }
    }
    
    private func createVertexDescriptor() -> MTLVertexDescriptor {
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
        return vertexDesc
    }
    
    private func createPipelineDescriptor(vp: MTLFunction, fp: MTLFunction, vertexDesc: MTLVertexDescriptor, pixelFormat: MTLPixelFormat, sampleCount: Int) -> MTLRenderPipelineDescriptor {
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = vp
        desc.fragmentFunction = fp
        desc.vertexDescriptor = vertexDesc
        desc.colorAttachments[0].pixelFormat = pixelFormat
        desc.colorAttachments[0].isBlendingEnabled = true
        desc.colorAttachments[0].rgbBlendOperation = .add
        desc.colorAttachments[0].alphaBlendOperation = .add
        desc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        desc.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        desc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        desc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        desc.sampleCount = sampleCount
        return desc
    }
    
    override func draw(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer, camera: Camera) {
        if groups.count > 0 {
            let renderPassDescriptor = Renderer.shared.createRenderPassWithColorAttachmentTexture(drawable.texture, clear: false)
            guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                return
            }
            encoder.label = "Primitive2D Encoder"
            encoder.pushDebugGroup("primitive2d")
            for g in groups {
                let linear = g.texture?.isLinear ?? true
                let tex = g.texture?.mtlTexture ?? Renderer.shared.whiteTexture
                encoder.setRenderPipelineState(linear ? pipelineState : sRgbPipelineState)
                encoder.setFragmentTexture(tex, index: 0)
                encoder.setVertexBuffer(g.spriteVB, offset: g.spriteVBoffset, index: 0)
                encoder.drawIndexedPrimitives(type: .triangle, indexCount: g.sprites.count * 6, indexType: .uint16, indexBuffer: g.spriteIB, indexBufferOffset: 0)
            }
            encoder.popDebugGroup()
            encoder.endEncoding()
        }
    }
    override func updateBuffers(_ syncBufferIndex: Int, camera: Camera) {
        for group in groups {
            group.updateBuffers(syncBufferIndex, camera: camera)
        }
    }
    
}
