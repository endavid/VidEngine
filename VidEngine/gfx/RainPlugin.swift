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
    private var pipelineState: MTLRenderPipelineState! = nil
    private var updateState: MTLRenderPipelineState! = nil
    private var raindropDoubleBuffer: MTLBuffer! = nil
    private var noiseTexture: MTLTexture! = nil
    private let maxNumberOfRaindrops = 2048
    private let sizeOfLineParticle = sizeof(Float) * 4 * 2
    private var vertexCount = 0
    private var particleCount = 0
    private var doubleBufferIndex = 0

    override init(device: MTLDevice, view: MTKView) {
        super.init(device: device, view: view)
        
        let defaultLibrary = device.newDefaultLibrary()!
        let fragmentProgram = defaultLibrary.newFunctionWithName("passThroughFragment")!
        let vertexRaindropProgram = defaultLibrary.newFunctionWithName("passVertexRaindrop")!
        let updateRaindropProgram = defaultLibrary.newFunctionWithName("updateRaindrops")!
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexRaindropProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineStateDescriptor.colorAttachments[0].blendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .Add
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .Add
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .SourceAlpha
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .SourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .DestinationAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .OneMinusSourceAlpha
        pipelineStateDescriptor.sampleCount = view.sampleCount
        
        let updateStateDescriptor = MTLRenderPipelineDescriptor()
        updateStateDescriptor.vertexFunction = updateRaindropProgram
        updateStateDescriptor.rasterizationEnabled = false // vertex output is void
        updateStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat // pixel format needs to be set
        
        do {
            try pipelineState = device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
            try updateState = device.newRenderPipelineStateWithDescriptor(updateStateDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
        
        // generate a large enough buffer to allow streaming vertices for 3 semaphore controlled frames
        raindropDoubleBuffer = device.newBufferWithLength(2 * maxNumberOfRaindrops * sizeOfLineParticle, options: [])
        raindropDoubleBuffer.label = "raindrop buffer"
        noiseTexture = createNoiseTexture(device: device, width: 128, height: 128)
        
        initVertexBuffer(2000)
    }
    
    override func execute(encoder: MTLRenderCommandEncoder) {
        // setVertexBuffer offset: How far the data is from the start of the buffer, in bytes
        // Check alignment in setVertexBuffer doc
        let bufferOffset = maxNumberOfRaindrops * sizeOfLineParticle
        encoder.pushDebugGroup("draw rain")
        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(raindropDoubleBuffer, offset: bufferOffset*doubleBufferIndex, atIndex: 0)
        encoder.drawPrimitives(.Line, vertexStart: 0, vertexCount: vertexCount, instanceCount: 1)
        encoder.popDebugGroup()
        encoder.pushDebugGroup("update raindrops")
        encoder.setRenderPipelineState(updateState)
        encoder.setVertexBuffer(raindropDoubleBuffer, offset: bufferOffset*doubleBufferIndex, atIndex: 0)
        encoder.setVertexBuffer(raindropDoubleBuffer, offset: bufferOffset*((doubleBufferIndex+1)%2), atIndex: 1)
        RenderManager.sharedInstance.setUniformBuffer(encoder, atIndex: 2)
        encoder.setVertexTexture(noiseTexture, atIndex: 0)
        encoder.drawPrimitives(.Point, vertexStart: 0, vertexCount: particleCount, instanceCount: 1)
        encoder.popDebugGroup()
        // swap buffers
        doubleBufferIndex = (doubleBufferIndex + 1) % 2
    }
    
    private func initVertexBuffer(numParticles: Int) {
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
                let vDatai = UnsafeMutablePointer<Float>(pData + maxNumberOfRaindrops * sizeOfLineParticle * i)
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