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
        let gBuffer = RenderManager.sharedInstance.gBuffer
        let renderPassDescriptor = RenderManager.sharedInstance.createRenderPassWithColorAttachmentTexture(gBuffer.lightTexture, clear: true)
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        encoder.label = "Deferred Lighting Encoder"
        encoder.pushDebugGroup("deferredLighting")
        drawDirectionalLights(encoder)
        encoder.popDebugGroup()
        encoder.endEncoding()
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
