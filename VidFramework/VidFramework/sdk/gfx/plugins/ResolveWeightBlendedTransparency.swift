//
//  ResolveWeightBlendedTransparency.swift
//  VidEngine
//
//  Created by David Gavilan on 2017/05/29.
//  Copyright © 2017 David Gavilan. All rights reserved.
//

import Foundation
import Metal
import MetalKit

// Weight-blended OIT
class ResolveWeightBlendedTransparency : GraphicPlugin {
    fileprivate var pipelineState: MTLRenderPipelineState! = nil
    
    override var label: String {
        get {
            return "ResolveOIT"
        }
    }
    
    init(device: MTLDevice, library: MTLLibrary, view: MTKView, gBuffer: GBuffer) {
        super.init(device: device, library: library, view: view)
        
        let fragmentProgram = library.makeFunction(name: "passResolveOIT")!
        let vertexProgram = library.makeFunction(name: "passThrough2DVertex")!
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        // should be .BGRA8Unorm_sRGB
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = gBuffer.shadedTexture.pixelFormat
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .oneMinusSourceAlpha
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .destinationAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .sourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipelineStateDescriptor.sampleCount = view.sampleCount
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
    }
    override func draw(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer, camera: Camera) {
        guard let renderer = Renderer.shared else {
            return
        }
        if !renderer.frameState.clearedTransparencyBuffer {
            return
        }
        let gBuffer = renderer.gBuffer
        let clear = !renderer.frameState.clearedBackbuffer
        let renderPassDescriptor = renderer.createRenderPassWithColorAttachmentTexture(gBuffer.shadedTexture, clear: clear)
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        encoder.label = self.label
        encoder.pushDebugGroup(self.label)
        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentTexture(gBuffer.lightTexture, index: 0)
        encoder.setFragmentTexture(gBuffer.revealTexture, index: 1)
        renderer.fullScreenQuad.draw(encoder: encoder)
        encoder.popDebugGroup()
        encoder.endEncoding()
        renderer.frameState.clearedBackbuffer = true
    }
}
