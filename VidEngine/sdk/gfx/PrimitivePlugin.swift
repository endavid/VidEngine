//
//  PrimitivePlugin.swift
//  VidEngine
//
//  Created by David Gavilan on 8/11/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

class PrimitivePlugin : GraphicPlugin {
    
    fileprivate var primitives : [Primitive] = []
    fileprivate var pipelineState: MTLRenderPipelineState! = nil
    fileprivate var depthState : MTLDepthStencilState! = nil
    
    func queue(_ primitive: Primitive) {
        let alreadyQueued = primitives.contains { $0 === primitive }
        if !alreadyQueued {
            // @todo insert in priority order
            primitives.append(primitive)
        }
    }
    
    func dequeue(_ primitive: Primitive) {
        let index = primitives.index { $0 === primitive }
        if let i = index {
            primitives.remove(at: i)
        }
    }
    
    override init(device: MTLDevice, view: MTKView) {
        super.init(device: device, view: view)
        
        let defaultLibrary = device.newDefaultLibrary()!
        let fragmentProgram = defaultLibrary.makeFunction(name: "passLightFragment")!
        let vertexProgram = defaultLibrary.makeFunction(name: "passLightGeometry")!
        
        // check TexturedVertex
        let vertexDesc = MTLVertexDescriptor()
        vertexDesc.attributes[0].format = .float3
        vertexDesc.attributes[0].offset = 0
        vertexDesc.attributes[0].bufferIndex = 0
        vertexDesc.attributes[1].format = .float3
        vertexDesc.attributes[1].offset = MemoryLayout<Vec3>.size
        vertexDesc.attributes[1].bufferIndex = 0
        vertexDesc.attributes[2].format = .float2
        vertexDesc.attributes[2].offset = MemoryLayout<Vec3>.size * 2
        vertexDesc.attributes[2].bufferIndex = 0
        vertexDesc.layouts[0].stepFunction = .perVertex
        vertexDesc.layouts[0].stride = MemoryLayout<TexturedVertex>.size
        
        let gBuffer = RenderManager.sharedInstance.gBuffer
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.vertexDescriptor = vertexDesc
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = gBuffer.albedoTexture.pixelFormat
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = false
        pipelineStateDescriptor.colorAttachments[1].pixelFormat = gBuffer.normalTexture.pixelFormat
        pipelineStateDescriptor.colorAttachments[1].isBlendingEnabled = false
        pipelineStateDescriptor.sampleCount = view.sampleCount
        pipelineStateDescriptor.depthAttachmentPixelFormat = gBuffer.depthTexture.pixelFormat
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.isDepthWriteEnabled = true
        depthDescriptor.depthCompareFunction = .less
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
            depthState = device.makeDepthStencilState(descriptor: depthDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
    }
    
    override func draw(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer, camera: Camera) {
        let whiteTexture = RenderManager.sharedInstance.whiteTexture
        let renderPassDescriptor = RenderManager.sharedInstance.createRenderPassWithGBuffer(true)
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        encoder.label = "Primitives Encoder"
        encoder.pushDebugGroup("primitives")
        encoder.setRenderPipelineState(pipelineState)
        encoder.setDepthStencilState(depthState)
        encoder.setFrontFacing(.counterClockwise)
        encoder.setCullMode(.back)
        encoder.setFragmentTexture(whiteTexture, at: 0)
        
        RenderManager.sharedInstance.setUniformBuffer(encoder, atIndex: 1)
        for p in self.primitives {
            p.draw(encoder)
        }
        encoder.popDebugGroup()
        encoder.endEncoding()
    }
    
    override func updateBuffers(_ syncBufferIndex: Int) {
        for p in primitives {
            p.updateBuffers(syncBufferIndex)
        }
    }
}
