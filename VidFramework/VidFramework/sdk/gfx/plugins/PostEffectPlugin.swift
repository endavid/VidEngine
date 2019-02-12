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
class PostEffectPlugin: GraphicPlugin {
    fileprivate var passThroughPipeline: MTLRenderPipelineState! = nil

    override var label: String {
        get {
            return "PostFx"
        }
    }
    
    init(device: MTLDevice, library: MTLLibrary, view: MTKView, blend: Bool) {
        super.init(device: device, library: library, view: view)
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = library.makeFunction(name: "passThrough2DVertex")
        desc.fragmentFunction = library.makeFunction(name: "passThroughTexturedFragment")
        // .bgra8Unorm_srgb, or .bgra10_XR_sRGB if wide color gamut
        desc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        if blend {
            desc.colorAttachments[0].isBlendingEnabled = true
            desc.colorAttachments[0].rgbBlendOperation = .add
            desc.colorAttachments[0].alphaBlendOperation = .add
            desc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            desc.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
            desc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            desc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        } else {
            desc.colorAttachments[0].isBlendingEnabled = false
        }
        desc.sampleCount = view.sampleCount
        do {
            try passThroughPipeline = device.makeRenderPipelineState(descriptor: desc)
        } catch let error {
            NSLog("Failed to create pipeline state: \(error.localizedDescription)")
        }
    }
    
    override func draw(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer, camera: Camera) {
        guard let renderer = Renderer.shared else {
            return
        }
        if !renderer.frameState.clearedBackbuffer {
            // nothing in backbuffer to dump to the drawable
            return
        }
        let clear = !renderer.frameState.clearedDrawable
        let renderPassDescriptor = renderer.createRenderPassWithColorAttachmentTexture(drawable.texture, clear: clear)
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        encoder.label = self.label
        passThrough(encoder: encoder, renderer: renderer, camera: camera)
        encoder.endEncoding()
        renderer.frameState.clearedDrawable = true
    }
    
    private func passThrough(encoder: MTLRenderCommandEncoder, renderer: Renderer, camera: Camera) {
        encoder.pushDebugGroup("PassThrough")
        encoder.setRenderPipelineState(passThroughPipeline)
        encoder.setFragmentTexture(renderer.gBuffer.shadedTexture, index: 0)
        renderer.fullScreenQuad.draw(encoder: encoder)
        encoder.popDebugGroup()
    }
    
}
