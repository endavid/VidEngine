//
//  PostEffectPlugin.swift
//  VidEngine
//
//  Created by David Gavilan on 2017/05/29.
//  Copyright © 2017 David Gavilan. All rights reserved.
//

import Foundation
import MetalKit

// At the moment, it just passes through
class PostEffectPlugin : GraphicPlugin {
    fileprivate var passThroughPipeline: MTLRenderPipelineState! = nil

    required init(device: MTLDevice, library: MTLLibrary, view: MTKView) {

        let passThroughDesc = MTLRenderPipelineDescriptor()
        passThroughDesc.vertexFunction = library.makeFunction(name: "passThrough2DVertex")
        passThroughDesc.fragmentFunction = library.makeFunction(name: "passThroughTexturedFragment")
        // should be .BGRA8Unorm_sRGB
        passThroughDesc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        passThroughDesc.colorAttachments[0].isBlendingEnabled = false
        passThroughDesc.sampleCount = view.sampleCount
        do {
            try passThroughPipeline = device.makeRenderPipelineState(descriptor: passThroughDesc)
        } catch let error {
            NSLog("Failed to create pipeline state: \(error.localizedDescription)")
        }
    }

    func draw(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer, camera: Camera) {
        let renderPassDescriptor = RenderManager.sharedInstance.createRenderPassWithColorAttachmentTexture(drawable.texture, clear: true)
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        encoder.label = "PostEffects"
        passThrough(encoder: encoder, camera: camera)
        encoder.endEncoding()
    }

    func updateBuffers(_ syncBufferIndex: Int) {

    }

    private func passThrough(encoder: MTLRenderCommandEncoder, camera: Camera) {
        let gBuffer = RenderManager.sharedInstance.gBuffer
        encoder.pushDebugGroup("PassThrough")
        encoder.setRenderPipelineState(passThroughPipeline)
        encoder.setFragmentTexture(gBuffer.shadedTexture, at: 0)
        RenderManager.sharedInstance.fullScreenQuad.draw(encoder: encoder)
        encoder.popDebugGroup()
    }

}
