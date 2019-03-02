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
    fileprivate var directionalState: MTLRenderPipelineState! = nil
    fileprivate var shLightState: MTLRenderPipelineState! = nil
    fileprivate var directionalLights : [DirectionalLight] = []
    fileprivate var shLights: [SHLight] = []
    
    override var label: String {
        get {
            return "DeferredLighting"
        }
    }
    
    override var isEmpty: Bool {
        get {
            return directionalLights.isEmpty && shLights.isEmpty
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
    
    func createPipelineDescriptor(device: MTLDevice, library: MTLLibrary, gBuffer: GBuffer, fragment: String, vertex: String) -> MTLRenderPipelineDescriptor {
        let fragmentProgram = library.makeFunction(name: fragment)!
        let vertexProgram = library.makeFunction(name: vertex)!
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = vertexProgram
        desc.fragmentFunction = fragmentProgram
        desc.colorAttachments[0].pixelFormat = gBuffer.lightTexture.pixelFormat
        desc.colorAttachments[0].isBlendingEnabled = true
        desc.colorAttachments[0].rgbBlendOperation = .add
        desc.colorAttachments[0].alphaBlendOperation = .add
        desc.colorAttachments[0].sourceRGBBlendFactor = .one
        desc.colorAttachments[0].sourceAlphaBlendFactor = .one
        desc.colorAttachments[0].destinationRGBBlendFactor = .one
        desc.colorAttachments[0].destinationAlphaBlendFactor = .one
        desc.sampleCount = gBuffer.lightTexture.sampleCount
        return desc
    }
    
    
    init(device: MTLDevice, library: MTLLibrary, view: MTKView, gBuffer: GBuffer) {
        super.init(device: device, library: library, view: view)
        let directionalDesc = createPipelineDescriptor(device: device, library: library, gBuffer: gBuffer, fragment: "lightAccumulationDirectionalLight", vertex: "directionalLightVertex")
        let shLightDesc = createPipelineDescriptor(device: device, library: library, gBuffer: gBuffer, fragment: "lightAccumulationSHLight", vertex: "shLightVertex")
        do {
            try directionalState = device.makeRenderPipelineState(descriptor: directionalDesc)
            try shLightState = device.makeRenderPipelineState(descriptor: shLightDesc)
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
        if !renderer.frameState.clearedGBuffer {
            return
        }
        let renderPassDescriptor = renderer.createLightAccumulationRenderPass(clear: true)
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        encoder.label = self.label
        drawDirectionalLights(encoder)
        drawSHLights(encoder)
        encoder.endEncoding()
        renderer.frameState.clearedLightbuffer = true
    }
    
    /// Draw all the directional lights with full-screen passes.
    /// We should compute the shadow maps before.
    /// Supposedly the shadow maps can be computed in parallel with the earlier pipeline.
    /// All non-shadow casting lights can be computed with a single draw call using instancing.
    fileprivate func drawDirectionalLights(_ encoder: MTLRenderCommandEncoder) {
        let renderer = Renderer.shared!
        encoder.pushDebugGroup(self.label+":directional")
        encoder.setRenderPipelineState(directionalState)
        encoder.setFragmentTexture(renderer.gBuffer.normalTexture, index: 0)
        renderer.setGraphicsDataBuffer(encoder, atIndex: 1)
        for l in directionalLights {
            encoder.setVertexBuffer(l.uniformBuffer, offset: l.bufferOffset, index: 2)
            renderer.fullScreenQuad.draw(encoder: encoder, instanceCount: l.numInstances)
        }
        encoder.popDebugGroup()
    }
    
    /// Spherical Harmonic lights are drawn inside the area defined
    /// by a CubePrimitive
    fileprivate func drawSHLights(_ encoder: MTLRenderCommandEncoder) {
        let renderer = Renderer.shared!
        let numIndices = CubePrimitive.numIndices
        encoder.pushDebugGroup(self.label+":shlights")
        encoder.setRenderPipelineState(shLightState)
        encoder.setFragmentTexture(renderer.gBuffer.normalTexture, index: 0)
        renderer.setGraphicsDataBuffer(encoder, atIndex: 1)
        for l in shLights {
            encoder.setVertexBuffer(l.vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBuffer(l.instanceBuffer, offset: l.bufferOffset, index: 2)
            encoder.setFragmentBuffer(l.shBuffer.irradiancesBuffer, offset: 0, index: 0)
            encoder.drawIndexedPrimitives(type: .triangle, indexCount: numIndices, indexType: .uint16, indexBuffer: l.indexBuffer, indexBufferOffset: 0)
        }
        encoder.popDebugGroup()
    }

    /// Draw all spot lights using spot light geometry.
    /// For shadows, same as directional lights.
    fileprivate func drawSpotLights(_ encoder: MTLRenderCommandEncoder) {
        
    }
    
    override func updateBuffers(_ syncBufferIndex: Int, camera: Camera) {
        for l in directionalLights {
            l.updateBuffers(syncBufferIndex)
        }
        for l in shLights {
            l.updateBuffers(syncBufferIndex)
        }
    }
}
