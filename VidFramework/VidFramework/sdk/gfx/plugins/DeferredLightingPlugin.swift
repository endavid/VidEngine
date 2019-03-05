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
    fileprivate var shGeometryState: MTLRenderPipelineState! = nil
    fileprivate var shLightDepthState: MTLDepthStencilState! = nil
    fileprivate var shLightDepthColorState: MTLDepthStencilState! = nil
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
    
    func createGeometryOnlyDescriptor(device: MTLDevice, library: MTLLibrary, gBuffer: GBuffer) -> MTLRenderPipelineDescriptor {
        let fragmentProgram = library.makeFunction(name: "dummyFragmentSHLight")!
        let vertexProgram = library.makeFunction(name: "shLightVertex")!
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = vertexProgram
        desc.fragmentFunction = fragmentProgram
        // no color attachment
        desc.depthAttachmentPixelFormat = gBuffer.depthTexture.pixelFormat
        desc.stencilAttachmentPixelFormat = gBuffer.stencilTexture.pixelFormat
        desc.sampleCount = gBuffer.stencilTexture.sampleCount
        return desc
    }
    
    func createSHLightPipelineDescriptor(device: MTLDevice, library: MTLLibrary, gBuffer: GBuffer) -> MTLRenderPipelineDescriptor {
        let desc = createPipelineDescriptor(device: device, library: library, gBuffer: gBuffer, fragment: "lightAccumulationSHLight", vertex: "shLightVertex")
        desc.depthAttachmentPixelFormat = gBuffer.depthTexture.pixelFormat
        desc.stencilAttachmentPixelFormat = gBuffer.stencilTexture.pixelFormat
        return desc
    }
    
    
    init(device: MTLDevice, library: MTLLibrary, view: MTKView, gBuffer: GBuffer) {
        super.init(device: device, library: library, view: view)
        let directionalDesc = createPipelineDescriptor(device: device, library: library, gBuffer: gBuffer, fragment: "lightAccumulationDirectionalLight", vertex: "directionalLightVertex")
        let shLightDesc = createSHLightPipelineDescriptor(device: device, library: library, gBuffer: gBuffer)
        let shGeomDesc = createGeometryOnlyDescriptor(device: device, library: library, gBuffer: gBuffer)
        let shLightDepthDesc = gBuffer.createDepthStencilDescriptorForAmbientLightGeometry()
        let shLightDepthColorDesc = gBuffer.createDepthStencilDescriptorForAmbientLight()
        do {
            try directionalState = device.makeRenderPipelineState(descriptor: directionalDesc)
            try shLightState = device.makeRenderPipelineState(descriptor: shLightDesc)
            try shGeometryState = device.makeRenderPipelineState(descriptor: shGeomDesc)
            shLightDepthState = device.makeDepthStencilState(descriptor: shLightDepthDesc)
            shLightDepthColorState = device.makeDepthStencilState(descriptor: shLightDepthColorDesc)
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
        drawLights(commandBuffer: commandBuffer)
        drawSHLights(commandBuffer: commandBuffer)
        renderer.frameState.clearedLightbuffer = true
    }
    
    fileprivate func drawLights(commandBuffer: MTLCommandBuffer) {
        let desc = Renderer.shared.createLightAccumulationRenderPass(clear: true, color: true, depthStencil: false)
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: desc) else {
            return
        }
        encoder.label = self.label
        drawDirectionalLights(encoder)
        encoder.endEncoding()
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
            renderer.fullScreenQuad.draw(encoder: encoder, instanceCount: l.instanceCount)
        }
        encoder.popDebugGroup()
    }
    
    fileprivate func drawSHLights(commandBuffer: MTLCommandBuffer) {
        let renderer = Renderer.shared!
        // it feels horrible to create 2 render encoders per SHLight!!!
        // but that seems the only way to do the 3 stencil passes...
        for l in shLights {
            let descStencil = renderer.createLightAccumulationRenderPass(clear: false, color: false, depthStencil: true)
            guard let encoderStencil = commandBuffer.makeRenderCommandEncoder(descriptor: descStencil) else {
                continue
            }
            encoderStencil.label = self.label+":SH(Stencil)"
            drawSHLightStencil(l, encoder: encoderStencil)
            encoderStencil.endEncoding()
            let descColor = renderer.createLightAccumulationRenderPass(clear: false, color: true, depthStencil: true)
            guard let encoderColor = commandBuffer.makeRenderCommandEncoder(descriptor: descColor) else {
                continue
            }
            encoderColor.label = self.label+":SH(Color)"
            drawSHLight(l, encoder: encoderColor)
            encoderColor.endEncoding()
        }
    }

    
    /// Spherical Harmonic lights are drawn inside the area defined
    /// by a CubePrimitive
    fileprivate func drawSHLightStencil(_ light: SHLight, encoder: MTLRenderCommandEncoder) {
        let renderer = Renderer.shared!
        encoder.pushDebugGroup("SH(\(light.identifier.uuidString))")
        encoder.setRenderPipelineState(shGeometryState)
        encoder.setDepthStencilState(shLightDepthState)
        encoder.setStencilReferenceValues(front: LightMask.none.rawValue, back: LightMask.all.rawValue)
        encoder.setFrontFacing(.counterClockwise)
        encoder.setDepthClipMode(.clamp)
        renderer.setGraphicsDataBuffer(encoder, atIndex: 1)
        encoder.setVertexBuffer(light.vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(light.instanceBuffer, offset: light.bufferOffset, index: 2)
        encoder.setCullMode(.front)
        light.draw(encoder: encoder)
        encoder.setCullMode(.back)
        light.draw(encoder: encoder)
        encoder.popDebugGroup()
    }
    
    fileprivate func drawSHLight(_ light: SHLight, encoder: MTLRenderCommandEncoder) {
        let renderer = Renderer.shared!
        encoder.pushDebugGroup("SH(\(light.identifier.uuidString))")
        encoder.setRenderPipelineState(shLightState)
        encoder.setDepthStencilState(shLightDepthColorState)
        encoder.setStencilReferenceValues(front: LightMask.ambient.rawValue, back: 0)
        encoder.setFrontFacing(.counterClockwise)
        encoder.setDepthClipMode(.clamp)
        renderer.setGraphicsDataBuffer(encoder, atIndex: 1)
        encoder.setVertexBuffer(light.vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(light.instanceBuffer, offset: light.bufferOffset, index: 2)
        encoder.setFragmentTexture(renderer.gBuffer.normalTexture, index: 0)
        encoder.setFragmentBuffer(light.irradianceBuffer, offset: 0, index: 0)
        encoder.setCullMode(.back)
        light.draw(encoder: encoder)
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
