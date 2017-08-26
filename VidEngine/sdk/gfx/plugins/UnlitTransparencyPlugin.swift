//
//  UnlitTransparencyPlugin.swift
//  VidEngine
//
//  Created by David Gavilan on 2017/05/29.
//  Copyright © 2017 David Gavilan. All rights reserved.
//

import Foundation
import MetalKit

/// Uses Weight-blended OIT
class UnlitTransparencyPlugin : GraphicPlugin {
    fileprivate var pipelineState: MTLRenderPipelineState! = nil
    fileprivate var textPipelineState: MTLRenderPipelineState! = nil
    fileprivate var depthState : MTLDepthStencilState! = nil
    fileprivate var textPrimitives : [TextPrimitive] = []
    fileprivate var primitives : [Primitive] = []
    
    
    func queue(_ primitive: Primitive) {
        if let textPrim = primitive as? TextPrimitive {
            let alreadyQueued = textPrimitives.contains { $0 === textPrim }
            if !alreadyQueued {
                textPrimitives.append(textPrim)
            }
        } else {
            let alreadyQueued = primitives.contains { $0 === primitive }
            if !alreadyQueued {
                primitives.append(primitive)
            }
        }
    }
    
    func dequeue(_ primitive: Primitive) {
        if let textPrim = primitive as? TextPrimitive {
            let index = textPrimitives.index { $0 === textPrim }
            if let i = index {
                textPrimitives.remove(at: i)
            }
        } else {
            let index = primitives.index { $0 === primitive }
            if let i = index {
                primitives.remove(at: i)
            }
        }
    }
    
    override init(device: MTLDevice, library: MTLLibrary, view: MTKView) {
        super.init(device: device, library: library, view: view)
        
        let pipelineStateDescriptor = RenderManager.sharedInstance.gBuffer.createOITPipelineDescriptor(device: device, library: library)
        let textPipelineStateDescriptor = RenderManager.sharedInstance.gBuffer.createOITPipelineDescriptor(device: device, library: library, fragmentShader: "passTextFragmentOIT")
        
        let depthDescriptor = RenderManager.sharedInstance.gBuffer.createDepthStencilDescriptor()
        depthDescriptor.isDepthWriteEnabled = false
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
            try textPipelineState = device.makeRenderPipelineState(descriptor: textPipelineStateDescriptor)
            depthState = device.makeDepthStencilState(descriptor: depthDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
    }
    
    override func draw(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer, camera: Camera) {
        let renderPassDescriptor = RenderManager.sharedInstance.createOITRenderPass(clear: true)
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        encoder.label = "Unlit Transparency Encoder"
        encoder.pushDebugGroup("Unlit OIT")
        encoder.setRenderPipelineState(pipelineState)
        encoder.setDepthStencilState(depthState)
        encoder.setFrontFacing(.counterClockwise)
        encoder.setCullMode(.back)
        RenderManager.sharedInstance.setGraphicsDataBuffer(encoder, atIndex: 1)
        drawPrimitives(primitives, encoder: encoder)
        encoder.setRenderPipelineState(textPipelineState)
        drawPrimitives(textPrimitives, encoder: encoder)
        encoder.popDebugGroup()
        encoder.endEncoding()
    }
        
    private func drawPrimitives(_ prims: [Primitive], encoder: MTLRenderCommandEncoder) {
        let whiteTexture = RenderManager.sharedInstance.whiteTexture
        var currentAlbedoTexture : MTLTexture? = nil
        
        for p in prims {
            if p.submeshes.count > 0 {
                encoder.setVertexBuffer(p.vertexBuffer, offset: 0, at: 0)
                encoder.setVertexBuffer(p.uniformBuffer, offset: 0, at: 2)
            }
            for mesh in p.submeshes {
                
                if currentAlbedoTexture !== mesh.albedoTexture {
                    if let tex = mesh.albedoTexture {
                        encoder.setFragmentTexture(tex, at: 0)
                    }
                    currentAlbedoTexture = mesh.albedoTexture
                }
                if currentAlbedoTexture == nil {
                    encoder.setFragmentTexture(whiteTexture, at: 0)
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
        for p in textPrimitives {
            p.updateBuffers(syncBufferIndex)
        }
    }
}
