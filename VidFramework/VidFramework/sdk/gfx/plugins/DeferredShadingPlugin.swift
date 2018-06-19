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

    override var label: String {
        get {
            return "DeferredShading"
        }
    }

    init(device: MTLDevice, library: MTLLibrary, view: MTKView, gBuffer: GBuffer) {
        super.init(device: device, library: library, view: view)

        let fragmentProgram = library.makeFunction(name: "passLightShading")!
        let vertexProgram = library.makeFunction(name: "passThrough2DVertex")!

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
        guard let renderer = Renderer.shared else {
            return
        }
        if !renderer.frameState.clearedLightbuffer {
            return
        }
        let gBuffer = renderer.gBuffer
        let renderPassDescriptor = renderer.createRenderPassWithColorAttachmentTexture(gBuffer.shadedTexture, clear: true)
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        encoder.label = "Deferred Shading Encoder"
        encoder.pushDebugGroup("deferredShading")
        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentTexture(gBuffer.albedoTexture, index: 0)
        encoder.setFragmentTexture(gBuffer.normalTexture, index: 1)
        renderer.fullScreenQuad.draw(encoder: encoder)
        encoder.popDebugGroup()
        encoder.endEncoding()
        renderer.frameState.clearedBackbuffer = true
    }
}
