//
//  DownsamplePlugin.swift
//  VidFramework
//
//  Created by David Gavilan on 2019/07/21.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

struct MiniGBuffer {
    let width: Int
    let height: Int
    let depthTexture: MTLTexture
    let normalTexture: MTLTexture
    
    init(device: MTLDevice, width: Int, height: Int) {
        self.width = width
        self.height = height
        let depthDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r32Float, width: width, height: height, mipmapped: false)
        depthDesc.usage = [.renderTarget, .shaderRead]
        let normalDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Snorm, width: width, height: height, mipmapped: false)
        normalDesc.usage = [.renderTarget, .shaderRead]
        depthTexture = device.makeTexture(descriptor: depthDesc)!
        depthTexture.label = "MiniG:Depth"
        normalTexture = device.makeTexture(descriptor: normalDesc)!
        normalTexture.label = "MiniG:Normal"
    }
}

/// Downsamples some of the textures in the GBuffer
/// so we can use them to optimize other plugins
class DownsamplePlugin: GraphicPlugin {
    fileprivate var renderState: MTLRenderPipelineState! = nil
    var miniGBuffer: MiniGBuffer
    var valid = false
    var downscaleLevel: Int
    
    override var label: String {
        get {
            return "Downsample"
        }
    }
    
    func createPipelineDescriptor(library: MTLLibrary) -> MTLRenderPipelineDescriptor {
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = library.makeFunction(name: "passThrough2DVertex")
        desc.fragmentFunction = library.makeFunction(name: "passThroughMRT2")
        desc.colorAttachments[0].pixelFormat = miniGBuffer.normalTexture.pixelFormat
        desc.colorAttachments[0].isBlendingEnabled = false
        desc.colorAttachments[1].pixelFormat = miniGBuffer.depthTexture.pixelFormat
        desc.colorAttachments[1].isBlendingEnabled = false
        desc.sampleCount = miniGBuffer.normalTexture.sampleCount
        return desc
    }
    
    func createRenderPass() -> MTLRenderPassDescriptor {
        let renderPass = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = miniGBuffer.normalTexture
        renderPass.colorAttachments[0].loadAction = .dontCare
        renderPass.colorAttachments[0].storeAction = .store
        renderPass.colorAttachments[1].texture = miniGBuffer.depthTexture
        renderPass.colorAttachments[1].loadAction = .dontCare
        renderPass.colorAttachments[1].storeAction = .store
        return renderPass
    }
    
    init(device: MTLDevice, library: MTLLibrary, view: MTKView, gBuffer: GBuffer, downscaleLevel: Int) {
        self.downscaleLevel = downscaleLevel
        miniGBuffer = MiniGBuffer(device: device, width: 1, height: 1)
        super.init(device: device, library: library, view: view)
        let desc = createPipelineDescriptor(library: library)
        do {
            try renderState = device.makeRenderPipelineState(descriptor: desc)
        } catch let error {
            NSLog("Failed to create pipeline state: \(error.localizedDescription)")
        }
    }
    
    override func draw(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer, camera: Camera) {
        valid = false
        guard let renderer = Renderer.shared else {
            return
        }
        if !renderer.frameState.clearedGBuffer {
            return
        }
        let gBuffer = renderer.gBuffer
        let w = gBuffer.width >> downscaleLevel
        let h = gBuffer.height >> downscaleLevel
        if w != miniGBuffer.width || h != miniGBuffer.height {
            miniGBuffer = MiniGBuffer(device: renderer.device, width: w, height: h)
        }
        let desc = createRenderPass()
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: desc) else {
            return
        }
        encoder.label = self.label
        encoder.setRenderPipelineState(renderState)
        encoder.setFragmentTexture(gBuffer.normalTexture, index: 0)
        encoder.setFragmentTexture(gBuffer.depthTexture, index: 1)
        renderer.fullScreenQuad.draw(encoder: encoder)
        encoder.endEncoding()
        valid = true
    }
}
