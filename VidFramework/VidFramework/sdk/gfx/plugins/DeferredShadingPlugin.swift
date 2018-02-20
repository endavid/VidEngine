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

    override init(device: MTLDevice, library: MTLLibrary, view: MTKView) {
        super.init(device: device, library: library, view: view)

        let fragmentProgram = library.makeFunction(name: "passLightShading")!
        let vertexProgram = library.makeFunction(name: "passThrough2DVertex")!

        let gBuffer = RenderManager.sharedInstance.gBuffer
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        // should be .BGRA8Unorm_sRGB
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = gBuffer.shadedTexture.pixelFormat
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = false
        pipelineStateDescriptor.sampleCount = view.sampleCount
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch let error {
            NSLog("Failed to create pipeline state: \(error.localizedDescription)")
        }
    }

    override func draw(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer, camera: Camera) {
        let gBuffer = RenderManager.sharedInstance.gBuffer
        let renderPassDescriptor = RenderManager.sharedInstance.createRenderPassWithColorAttachmentTexture(gBuffer.shadedTexture, clear: true)
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        encoder?.label = "Deferred Shading Encoder"
        encoder?.pushDebugGroup("deferredShading")
        encoder?.setRenderPipelineState(pipelineState)
        encoder?.setFragmentTexture(gBuffer.albedoTexture, index: 0)
        encoder?.setFragmentTexture(gBuffer.normalTexture, index: 1)
        RenderManager.sharedInstance.fullScreenQuad.draw(encoder: encoder!)
        encoder?.popDebugGroup()
        encoder?.endEncoding()
    }
}
