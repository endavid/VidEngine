//
//  PrimitivePlugin.swift
//  VidEngine
//
//  Created by David Gavilan on 8/11/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

class PrimitivePlugin: GraphicPlugin {
    
    fileprivate var primitives : [Primitive] = []
    fileprivate var dots: [Dots3D] = []
    fileprivate var wires: [WirePrimitive] = []
    fileprivate var primState: MTLRenderPipelineState! = nil
    fileprivate var dotState: MTLRenderPipelineState! = nil
    fileprivate var wireState: MTLRenderPipelineState! = nil
    var depthState : MTLDepthStencilState! = nil
    
    override var label: String {
        get {
            return "GenericPrimitives"
        }
    }
    
    override var isEmpty: Bool {
        get {
            return primitives.isEmpty && dots.isEmpty
        }
    }
    
    func queue(_ primitive: Primitive) {
        let alreadyQueued = primitives.contains { $0 === primitive }
        if !alreadyQueued {
            primitives.append(primitive)
        }
    }
    func queue(_ dot: Dots3D) {
        let alreadyQueued = dots.contains { $0 === dot }
        if !alreadyQueued {
            dots.append(dot)
        }
    }
    func queue(_ wire: WirePrimitive) {
        let alreadyQueued = wires.contains { $0 === wire }
        if !alreadyQueued {
            wires.append(wire)
        }
    }
    
    func dequeue(_ primitive: Primitive) {
        let index = primitives.index { $0 === primitive }
        if let i = index {
            primitives.remove(at: i)
        }
    }
    func dequeue(_ dot: Dots3D) {
        let index = dots.index { $0 === dot }
        if let i = index {
            dots.remove(at: i)
        }
    }
    func dequeue(_ wire: WirePrimitive) {
        let index = wires.index { $0 === wire }
        if let i = index {
            wires.remove(at: i)
        }
    }
    
    func createPipelineDescriptor(device: MTLDevice, library: MTLLibrary, gBuffer: GBuffer) -> MTLRenderPipelineDescriptor {
        return gBuffer.createPipelineDescriptor(device: device, library: library)
    }
    func createDepthDescriptor(gBuffer: GBuffer) -> MTLDepthStencilDescriptor {
        return gBuffer.createDepthDescriptor()
    }
    func createDotsDescriptor(device: MTLDevice, library: MTLLibrary, gBuffer: GBuffer) -> MTLRenderPipelineDescriptor {
        return gBuffer.createPipelineDescriptor(device: device, library: library)
    }
    func createWiresDescriptor(device: MTLDevice, library: MTLLibrary, gBuffer: GBuffer) -> MTLRenderPipelineDescriptor? {
        return nil
    }
    
    func createEncoder(commandBuffer: MTLCommandBuffer) -> MTLRenderCommandEncoder? {
        let renderer = Renderer.shared!
        let clear = !renderer.frameState.clearedGBuffer
        let renderPassDescriptor = renderer.createRenderPassWithGBuffer(clear: clear)
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        if let e = encoder {
            e.label = self.label
            renderer.frameState.clearedGBuffer = true
        }
        return encoder
    }
    
    init(device: MTLDevice, library: MTLLibrary, view: MTKView, gBuffer: GBuffer) {
        super.init(device: device, library: library, view: view)
        
        let pipelineDesc = createPipelineDescriptor(device: device, library: library, gBuffer: gBuffer)
        let depthDesc = createDepthDescriptor(gBuffer: gBuffer)
        let dotsDesc = createDotsDescriptor(device: device, library: library, gBuffer: gBuffer)
        do {
            try primState = device.makeRenderPipelineState(descriptor: pipelineDesc)
            try dotState = device.makeRenderPipelineState(descriptor: dotsDesc)
            if let d = createWiresDescriptor(device: device, library: library, gBuffer: gBuffer) {
                try wireState = device.makeRenderPipelineState(descriptor: d)
            }
            depthState = device.makeDepthStencilState(descriptor: depthDesc)
        } catch let error {
            NSLog("Failed to create pipeline state, error \(error)")
        }
    }
    
    override func draw(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer, camera: Camera) {
        if isEmpty {
            return
        }
        guard let encoder = createEncoder(commandBuffer: commandBuffer) else {
            return
        }
        encoder.label = self.label
        draw(encoder: encoder)
        encoder.endEncoding()
    }
    
    func draw(encoder: MTLRenderCommandEncoder) {
        drawPrimitives(encoder: encoder)
        drawDots(encoder: encoder)
        drawWires(encoder: encoder)
    }

    private func drawPrimitives(encoder: MTLRenderCommandEncoder) {
        encoder.pushDebugGroup(self.label+":primitives")
        encoder.setRenderPipelineState(primState)
        encoder.setDepthStencilState(depthState)
        // the default is CW, but the default in OpenGL is CCW
        // --which makes more sense if you think of "unscrewing"
        //   and the normal direction of the vector product
        encoder.setFrontFacing(.counterClockwise)
        encoder.setCullMode(.back)
        Renderer.shared.setGraphicsDataBuffer(encoder, atIndex: 1)
        PrimitivePlugin.drawAll(encoder: encoder, primitives: self.primitives, defaultTexture: Renderer.shared.whiteTexture)
        encoder.popDebugGroup()
    }
    
    private func drawDots(encoder: MTLRenderCommandEncoder) {
        if dots.isEmpty {
            return
        }
        encoder.pushDebugGroup(self.label+":dots")
        encoder.setRenderPipelineState(dotState)
        encoder.setCullMode(.none)
        for p in dots {
            encoder.setVertexBuffer(p.vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBuffer(p.colorBuffer, offset: 0, index: 2)
            encoder.setVertexBuffer(p.instanceBuffer, offset: p.bufferOffset, index: 3)
            p.draw(encoder: encoder)
        }
        encoder.popDebugGroup()
    }
    
    private func drawWires(encoder: MTLRenderCommandEncoder) {
        if wires.isEmpty {
            return
        }
        encoder.pushDebugGroup(self.label+":wires")
        encoder.setRenderPipelineState(wireState)
        encoder.setCullMode(.none)
        for w in wires {
            encoder.setVertexBuffer(w.vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBuffer(w.instanceBuffer, offset: 0, index: 2)
            w.draw(encoder: encoder)
        }
        encoder.popDebugGroup()
    }
    
    static func drawAll(encoder: MTLRenderCommandEncoder, primitives: [Primitive], defaultTexture: MTLTexture) {
        var currentAlbedoTexture : MTLTexture? = nil
        for p in primitives {
            if p.submeshes.count > 0 {
                encoder.setVertexBuffer(p.vertexBuffer, offset: 0, index: 0)
                encoder.setVertexBuffer(p.uniformBuffer, offset: p.bufferOffset, index: 2)
            }
            for mesh in p.submeshes {
                if currentAlbedoTexture !== mesh.albedoTexture {
                    if let tex = mesh.albedoTexture {
                        encoder.setFragmentTexture(tex, index: 0)
                    }
                    currentAlbedoTexture = mesh.albedoTexture
                }
                if currentAlbedoTexture == nil {
                    encoder.setFragmentTexture(defaultTexture, index: 0)
                    currentAlbedoTexture = defaultTexture
                }
                p.drawMesh(encoder: encoder, mesh: mesh)
            }
        }
    }
    
    override func updateBuffers(_ syncBufferIndex: Int, camera _: Camera) {
        for p in primitives {
            p.updateBuffers(syncBufferIndex)
        }
        for p in dots {
            p.updateBuffers(syncBufferIndex)
        }
        for w in wires {
            w.updateBuffers(syncBufferIndex)
        }
    }
}
