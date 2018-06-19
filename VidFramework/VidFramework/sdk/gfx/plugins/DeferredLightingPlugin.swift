//
//  DeferredLighting.swift
//  VidEngine
//
//  Created by David Gavilan on 9/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import MetalKit

class DeferredLightingPlugin : GraphicPlugin {
    // @todo split in different queues, one per type
    fileprivate var lights : [LightSource] = []

    override var label: String {
        get {
            return "DeferredLighting"
        }
    }

    override var isEmpty: Bool {
        get {
            return lights.isEmpty
        }
    }

    func queue(_ light: LightSource) {
        let alreadyQueued = lights.contains { $0 === light }
        if !alreadyQueued {
            lights.append(light)
        }
    }
    func dequeue(_ light: LightSource) {
        let index = lights.index { $0 === light }
        if let i = index {
            lights.remove(at: i)
        }
    }
    override init(device: MTLDevice, library: MTLLibrary, view: MTKView) {
        super.init(device: device, library: library, view: view)
    }
    override func draw(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer, camera: Camera) {
        if isEmpty {
            return
        }
        guard let renderer = Renderer.shared else {
            return
        }
        let gBuffer = renderer.gBuffer
        let renderPassDescriptor = renderer.createRenderPassWithColorAttachmentTexture(gBuffer.lightTexture, clear: true)
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        encoder.label = self.label
        encoder.pushDebugGroup(self.label+":directional")
        drawDirectionalLights(encoder)
        encoder.popDebugGroup()
        encoder.endEncoding()
        renderer.frameState.clearedLightbuffer = true
    }

    /// Draw all the directional lights with full-screen passes.
    /// We should compute the shadow maps before.
    /// Supposedly the shadow maps can be computed in parallel with the earlier pipeline.
    /// All non-shadow casting lights can be computed with a single draw call using instancing.
    fileprivate func drawDirectionalLights(_ encoder: MTLRenderCommandEncoder) {
        //encoder.setRenderPipelineState(directionalLightsState)

    }

    /// Draw all spot lights using spot light geometry.
    /// For shadows, same as directional lights.
    fileprivate func drawSpotLights(_ encoder: MTLRenderCommandEncoder) {

    }
}
