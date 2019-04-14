//
//  PrimitivePlugin.swift
//  VidEngine
//
//  Created by David Gavilan on 8/4/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

class RainPlugin: GraphicPlugin {
    fileprivate var pipelineState: MTLRenderPipelineState! = nil
    fileprivate var updateState: MTLRenderPipelineState! = nil
    fileprivate var rains: [Rain] = []
    
    override var label: String {
        get {
            return "Rain"
        }
    }
    
    override var isEmpty: Bool {
        get {
            return rains.isEmpty
        }
    }
    
    func queue(_ rain: Rain) {
        let alreadyQueued = rains.contains { $0 === rain }
        if !alreadyQueued {
            rains.append(rain)
        }
    }
    func dequeue(_ rain: Rain) {
        let index = rains.firstIndex { $0 === rain }
        if let i = index {
            rains.remove(at: i)
        }
    }

    override init(device: MTLDevice, library: MTLLibrary, view: MTKView) {
        super.init(device: device, library: library, view: view)
        
        let fragmentProgram = library.makeFunction(name: "passThroughFragment")!
        let vertexRaindropProgram = library.makeFunction(name: "passVertexRaindrop")!
        let updateRaindropProgram = library.makeFunction(name: "updateRaindrops")!
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexRaindropProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .destinationAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipelineStateDescriptor.sampleCount = view.sampleCount
        
        let updateStateDescriptor = MTLRenderPipelineDescriptor()
        updateStateDescriptor.vertexFunction = updateRaindropProgram
        updateStateDescriptor.isRasterizationEnabled = false // vertex output is void
        updateStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat // pixel format needs to be set
        
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
            try updateState = device.makeRenderPipelineState(descriptor: updateStateDescriptor)
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
        let clear = !renderer.frameState.clearedDrawable
        let renderPassDescriptor = renderer.createRenderPassWithColorAttachmentTexture(drawable.texture, clear: clear)
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        for rain in rains {
            encoder.pushDebugGroup(self.label+":draw")
            encoder.setRenderPipelineState(pipelineState)
            rain.draw(encoder: encoder)
            encoder.popDebugGroup()
            encoder.pushDebugGroup(self.label+":update")
            encoder.setRenderPipelineState(updateState)
            rain.update(encoder: encoder)
            encoder.popDebugGroup()
            rain.swapBuffers()
        }
        encoder.endEncoding()
        renderer.frameState.clearedDrawable = true
    }
    

}
