//
//  DeferredShadingPlugin.swift
//  VidEngine
//
//  Created by David Gavilan on 9/6/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

class DeferredShadingPlugin : GraphicPlugin {
    fileprivate var pipelineState: MTLRenderPipelineState! = nil
    fileprivate let indexBuffer : MTLBuffer!
    fileprivate let vertexBuffer : MTLBuffer!

    override init(device: MTLDevice, view: MTKView) {
        indexBuffer = RenderManager.sharedInstance.createIndexBuffer("fullscreen IB", elements: [0, 2, 1, 3])
        vertexBuffer = device.makeBuffer(length: 4 * MemoryLayout<Vec4>.size, options: [])
        vertexBuffer.label = "fullscreen VB"
        super.init(device: device, view: view)
        
        let vb = vertexBuffer.contents().assumingMemoryBound(to: Vec4.self)
        // (x, y, u, v)
        vb[0] = Vec4(-1, -1, 0, 1)
        vb[1] = Vec4(-1,  1, 0, 0)
        vb[2] = Vec4( 1, -1, 1, 1)
        vb[3] = Vec4( 1,  1, 1, 0)
        
        let defaultLibrary = device.newDefaultLibrary()!
        let fragmentProgram = defaultLibrary.makeFunction(name: "passLightShading")!
        let vertexProgram = defaultLibrary.makeFunction(name: "passThrough2DVertex")!
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        // should be .BGRA8Unorm_sRGB
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = false
        pipelineStateDescriptor.sampleCount = view.sampleCount
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
    }
    
    override func draw(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer, camera: Camera) {
        let gBuffer = RenderManager.sharedInstance.gBuffer
        let renderPassDescriptor = RenderManager.sharedInstance.createRenderPassWithColorAttachmentTexture(drawable.texture, clear: true)
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        encoder.label = "Deferred Shading Encoder"
        encoder.pushDebugGroup("deferredShading")
        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentTexture(gBuffer.albedoTexture, at: 0)
        encoder.setFragmentTexture(gBuffer.normalTexture, at: 1)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
        encoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: 4, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        encoder.popDebugGroup()
        encoder.endEncoding()
    }    
}
