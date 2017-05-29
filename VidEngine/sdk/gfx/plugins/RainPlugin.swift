//
//  PrimitivePlugin.swift
//  VidEngine
//
//  Created by David Gavilan on 8/4/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

class RainPlugin : GraphicPlugin {
    fileprivate var pipelineState: MTLRenderPipelineState! = nil
    fileprivate var updateState: MTLRenderPipelineState! = nil
    fileprivate var raindropDoubleBuffer: MTLBuffer! = nil
    fileprivate var noiseTexture: MTLTexture! = nil
    fileprivate let maxNumberOfRaindrops = 2048
    fileprivate let sizeOfLineParticle = MemoryLayout<Float>.size * 4 * 2
    fileprivate var vertexCount = 0
    fileprivate var particleCount = 0
    fileprivate var doubleBufferIndex = 0

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
            print("Failed to create pipeline state, error \(error)")
        }
        
        raindropDoubleBuffer = device.makeBuffer(length: 2 * maxNumberOfRaindrops * sizeOfLineParticle, options: [])
        raindropDoubleBuffer.label = "raindrop buffer"
        noiseTexture = createNoiseTexture(device: device, width: 128, height: 128)
        
        initVertexBuffer(2000)
    }
    
    override func draw(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer, camera: Camera) {
        let renderPassDescriptor = RenderManager.sharedInstance.createRenderPassWithColorAttachmentTexture(drawable.texture, clear: false)
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        // setVertexBuffer offset: How far the data is from the start of the buffer, in bytes
        // Check alignment in setVertexBuffer doc
        let bufferOffset = maxNumberOfRaindrops * sizeOfLineParticle
        encoder.pushDebugGroup("draw rain")
        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(raindropDoubleBuffer, offset: bufferOffset*doubleBufferIndex, at: 0)
        encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: vertexCount, instanceCount: 1)
        encoder.popDebugGroup()
        encoder.pushDebugGroup("update raindrops")
        encoder.setRenderPipelineState(updateState)
        encoder.setVertexBuffer(raindropDoubleBuffer, offset: bufferOffset*doubleBufferIndex, at: 0)
        encoder.setVertexBuffer(raindropDoubleBuffer, offset: bufferOffset*((doubleBufferIndex+1)%2), at: 1)
        RenderManager.sharedInstance.setGraphicsDataBuffer(encoder, atIndex: 2)
        encoder.setVertexTexture(noiseTexture, at: 0)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleCount, instanceCount: 1)
        encoder.popDebugGroup()
        // swap buffers
        doubleBufferIndex = (doubleBufferIndex + 1) % 2
        encoder.endEncoding()
    }
    
    fileprivate func initVertexBuffer(_ numParticles: Int) {
        // vData is pointer to the MTLBuffer's Float data contents
        let pData = raindropDoubleBuffer.contents()
        particleCount = Min(maxNumberOfRaindrops, b: numParticles)
        vertexCount = 2 * particleCount
        let vertexSize = 4
        let dropLength : Float = 0.1
        for p in 0..<particleCount {
            let x = 2 * Randf() - 1
            let y = 1 + 2.4 * Randf()
            let dropSpeed = -2 * (0.9 + 0.2 * Randf())
            for i in 0..<2 { // Double buffer
                let vDatai = pData.advanced(by: maxNumberOfRaindrops * sizeOfLineParticle * i).assumingMemoryBound(to: Float.self)
                vDatai[2*vertexSize*p] = x
                vDatai[2*vertexSize*p+1] = y
                vDatai[2*vertexSize*p+2] = 0
                vDatai[2*vertexSize*p+3] = dropSpeed
                vDatai[2*vertexSize*p+4] = x
                vDatai[2*vertexSize*p+5] = y - dropLength
                vDatai[2*vertexSize*p+6] = 0
                vDatai[2*vertexSize*p+7] = dropSpeed
            }
        }
    }
}
