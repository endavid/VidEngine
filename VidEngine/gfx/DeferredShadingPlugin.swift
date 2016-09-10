//
//  DeferredShadingPlugin.swift
//  VidEngine
//
//  Created by David Gavilan on 9/6/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

class DeferredShadingPlugin : GraphicPlugin {
    private var pipelineState: MTLRenderPipelineState! = nil
    private var depthState : MTLDepthStencilState! = nil
    private let indexBuffer : MTLBuffer!
    private let vertexBuffer : MTLBuffer!
    private var noiseTexture: MTLTexture! = nil

    override init(device: MTLDevice, view: MTKView) {
        indexBuffer = RenderManager.sharedInstance.createIndexBuffer("fullscreen IB", elements: [0, 2, 1, 3])
        vertexBuffer = device.newBufferWithLength(4 * sizeof(Vec4), options: [])
        vertexBuffer.label = "fullscreen VB"
        super.init(device: device, view: view)
        
        let vb = UnsafeMutablePointer<Vec4>(vertexBuffer.contents())
        // (x, y, u, v)
        vb[0] = Vec4(-1, -1, 0, 0)
        vb[1] = Vec4(-1,  1, 0, 1)
        vb[2] = Vec4( 1, -1, 1, 0)
        vb[3] = Vec4( 1,  1, 1, 1)
        
        let defaultLibrary = device.newDefaultLibrary()!
        let fragmentProgram = defaultLibrary.newFunctionWithName("passThroughTexturedFragment")!
        let vertexProgram = defaultLibrary.newFunctionWithName("passThrough2DVertex")!
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        // should be .BGRA8Unorm_sRGB
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        print(view.colorPixelFormat)
        pipelineStateDescriptor.colorAttachments[0].blendingEnabled = false
        pipelineStateDescriptor.sampleCount = view.sampleCount
        pipelineStateDescriptor.depthAttachmentPixelFormat = .Depth32Float
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthWriteEnabled = false
        depthDescriptor.depthCompareFunction = .Always
        do {
            try pipelineState = device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
            depthState = device.newDepthStencilStateWithDescriptor(depthDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
        noiseTexture = createNoiseTexture(device: device, width: 128, height: 128)

    }
    
    override func execute(encoder: MTLRenderCommandEncoder) {
        encoder.pushDebugGroup("deferredShading")
        encoder.setRenderPipelineState(pipelineState)
        encoder.setDepthStencilState(depthState)
        encoder.setFragmentTexture(noiseTexture, atIndex: 0)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
        encoder.drawIndexedPrimitives(.TriangleStrip, indexCount: 4, indexType: .UInt16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        encoder.popDebugGroup()
    }
}
