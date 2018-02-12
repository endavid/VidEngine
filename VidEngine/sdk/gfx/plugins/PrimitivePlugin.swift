//
//  PrimitivePlugin.swift
//  VidEngine
//
//  Created by David Gavilan on 8/11/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

class PrimitivePlugin : GraphicPlugin {
    
    fileprivate var primitives : [Primitive] = []
    fileprivate var pipelineState: MTLRenderPipelineState! = nil
    fileprivate var depthState : MTLDepthStencilState! = nil
    
    func queue(_ primitive: Primitive) {
        let alreadyQueued = primitives.contains { $0 === primitive }
        if !alreadyQueued {
            primitives.append(primitive)
        }
    }
    
    func dequeue(_ primitive: Primitive) {
        let index = primitives.index { $0 === primitive }
        if let i = index {
            primitives.remove(at: i)
        }
    }
    
    override init(device: MTLDevice, library: MTLLibrary, view: MTKView) {
        super.init(device: device, library: library, view: view)
        
        let pipelineStateDescriptor = RenderManager.sharedInstance.gBuffer.createPipelineDescriptor(device: device, library: library)
        let depthDescriptor = RenderManager.sharedInstance.gBuffer.createDepthStencilDescriptor()
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
            depthState = device.makeDepthStencilState(descriptor: depthDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
    }
    
    override func draw(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer, camera: Camera) {
        let renderPassDescriptor = RenderManager.sharedInstance.createRenderPassWithGBuffer(true)
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        encoder?.label = "Primitives Encoder"
        encoder?.pushDebugGroup("primitives")
        encoder?.setRenderPipelineState(pipelineState)
        encoder?.setDepthStencilState(depthState)
        encoder?.setFrontFacing(.counterClockwise)
        encoder?.setCullMode(.back)
        RenderManager.sharedInstance.setGraphicsDataBuffer(encoder!, atIndex: 1)
        drawPrimitives(encoder: encoder!)
        encoder?.popDebugGroup()
        encoder?.endEncoding()
    }
    
    private func drawPrimitives(encoder: MTLRenderCommandEncoder) {
        let whiteTexture = RenderManager.sharedInstance.whiteTexture
        var currentAlbedoTexture : MTLTexture? = nil
        
        for p in self.primitives {
            if p.submeshes.count > 0 {
                encoder.setVertexBuffer(p.vertexBuffer, offset: 0, index: 0)
                encoder.setVertexBuffer(p.uniformBuffer, offset: 0, index: 2)
            }
            for mesh in p.submeshes {
                if currentAlbedoTexture !== mesh.albedoTexture {
                    if let tex = mesh.albedoTexture {
                        encoder.setFragmentTexture(tex, index: 0)
                    }
                    currentAlbedoTexture = mesh.albedoTexture
                }
                if currentAlbedoTexture == nil {
                    encoder.setFragmentTexture(whiteTexture, index: 0)
                    currentAlbedoTexture = whiteTexture
                }
                p.drawMesh(encoder: encoder, mesh: mesh)
            }
        }
    }
    
    override func updateBuffers(_ syncBufferIndex: Int) {
        for p in primitives {
            p.updateBuffers(syncBufferIndex)
        }
    }
}
