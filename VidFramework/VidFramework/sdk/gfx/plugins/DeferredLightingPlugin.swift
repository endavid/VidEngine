//
//  DeferredLighting.swift
//  VidEngine
//
//  Created by David Gavilan on 9/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

class DeferredLightingPlugin: GraphicPlugin {
    fileprivate var pipelineState: MTLRenderPipelineState! = nil
    fileprivate var directionalLights : [DirectionalLight] = []
    fileprivate var shLights: [SHLight] = []
    
    override var label: String {
        get {
            return "DeferredLighting"
        }
    }
    
    override var isEmpty: Bool {
        get {
            return directionalLights.isEmpty
        }
    }
    
    func queue(_ light: LightSource) {
        if let l = light as? DirectionalLight {
            let alreadyQueued = directionalLights.contains { $0 === l }
            if !alreadyQueued {
                directionalLights.append(l)
            }
        } else if let l = light as? SHLight {
            let alreadyQueued = shLights.contains { $0 === l }
            if !alreadyQueued {
                shLights.append(l)
            }
        } else {
            NSLog("LightSource \(light.name) -- unsupported type")
        }
    }
    func dequeue(_ light: LightSource) {
        if let l = light as? DirectionalLight {
            let index = directionalLights.index { $0 === l }
            if let i = index {
                directionalLights.remove(at: i)
            }
        } else if let l = light as? SHLight {
            let index = shLights.index { $0 === l }
            if let i = index {
                shLights.remove(at: i)
            }
        }
    }
    init(device: MTLDevice, library: MTLLibrary, view: MTKView, gBuffer: GBuffer) {
        super.init(device: device, library: library, view: view)
        // for directional lights only atm
        let fragmentProgram = library.makeFunction(name: "lightAccumulationDirectionalLight")!
        let vertexProgram = library.makeFunction(name: "directionalLightVertex")!
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = gBuffer.lightTexture.pixelFormat
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        pipelineStateDescriptor.sampleCount = view.sampleCount
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch let error {
            NSLog("Failed to create pipeline state, error \(error)")
        }
    }
    override func draw(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer, camera: Camera) {
        if isEmpty {
            return
        }
        guard let renderer = Renderer.shared else {
            return
        }
        let renderPassDescriptor = renderer.createLightAccumulationRenderPass(clear: true)
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        encoder.label = self.label
        encoder.pushDebugGroup(self.label+":directional")
        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentTexture(renderer.gBuffer.normalTexture, index: 0)
        renderer.setGraphicsDataBuffer(encoder, atIndex: 1)
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
        for l in directionalLights {
            encoder.setVertexBuffer(l.uniformBuffer, offset: l.bufferOffset, index: 2)
            Renderer.shared.fullScreenQuad.draw(encoder: encoder, instanceCount: l.numInstances)
        }
    }

    /// Draw all spot lights using spot light geometry.
    /// For shadows, same as directional lights.
    fileprivate func drawSpotLights(_ encoder: MTLRenderCommandEncoder) {
        
    }
    
    override func updateBuffers(_ syncBufferIndex: Int, camera: Camera) {
        for l in directionalLights {
            l.updateBuffers(syncBufferIndex)
        }
    }
}
