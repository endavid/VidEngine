//
//  PostEffectPlugin.swift
//  VidEngine
//
//  Created by David Gavilan on 2017/05/29.
//  Copyright © 2017 David Gavilan. All rights reserved.
//

import Foundation
import Metal
import MetalKit

// At the moment, it just passes through
class PostEffectPlugin : GraphicPlugin {
    fileprivate var passThroughPipeline: MTLRenderPipelineState! = nil

    override init(device: MTLDevice, library: MTLLibrary, view: MTKView) {
        super.init(device: device, library: library, view: view)
        let passThroughDesc = MTLRenderPipelineDescriptor()
        passThroughDesc.vertexFunction = library.makeFunction(name: "passThrough2DVertex")
        passThroughDesc.fragmentFunction = library.makeFunction(name: "passThroughTexturedFragment")
        // .bgra8Unorm_srgb, or .bgra10_XR_sRGB if wide color gamut
        passThroughDesc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        passThroughDesc.colorAttachments[0].isBlendingEnabled = false
        passThroughDesc.sampleCount = view.sampleCount
        do {
            try passThroughPipeline = device.makeRenderPipelineState(descriptor: passThroughDesc)
        } catch let error {
            NSLog("Failed to create pipeline state: \(error.localizedDescription)")
        }
    }
    
    override func draw(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer, camera: Camera) {
        let renderPassDescriptor = Renderer.shared.createRenderPassWithColorAttachmentTexture(drawable.texture, clear: true)
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        encoder?.label = "PostEffects"
        passThrough(encoder: encoder!, camera: camera)
        encoder?.endEncoding()
    }
    
    private func passThrough(encoder: MTLRenderCommandEncoder, camera: Camera) {
        let gBuffer = Renderer.shared.gBuffer
        encoder.pushDebugGroup("PassThrough")
        encoder.setRenderPipelineState(passThroughPipeline)
        encoder.setFragmentTexture(gBuffer.shadedTexture, index: 0)
        Renderer.shared.fullScreenQuad.draw(encoder: encoder)
        encoder.popDebugGroup()
    }
    
}
