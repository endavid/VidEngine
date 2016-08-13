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
    
    private var primitives : [Primitive] = []
    private var pipelineState: MTLRenderPipelineState! = nil
    
    override init(device: MTLDevice, view: MTKView) {
        super.init(device: device, view: view)
        
        let defaultLibrary = device.newDefaultLibrary()!
        let fragmentProgram = defaultLibrary.newFunctionWithName("passThroughFragment")!
        let vertexProgram = defaultLibrary.newFunctionWithName("passGeometry")!
        
        // check TexturedVertex
        let vertexDesc = MTLVertexDescriptor()
        vertexDesc.attributes[0].format = .Float3
        vertexDesc.attributes[0].offset = 0
        vertexDesc.attributes[0].bufferIndex = 0
        vertexDesc.attributes[1].format = .Float3
        vertexDesc.attributes[1].offset = sizeof(Vec3)
        vertexDesc.attributes[1].bufferIndex = 0
        vertexDesc.attributes[2].format = .Float2
        vertexDesc.attributes[2].offset = sizeof(Vec3) * 2
        vertexDesc.attributes[2].bufferIndex = 0
        vertexDesc.layouts[0].stepFunction = .PerVertex
        vertexDesc.layouts[0].stride = sizeof(TexturedVertex)
        
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.vertexDescriptor = vertexDesc
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineStateDescriptor.colorAttachments[0].blendingEnabled = false
        pipelineStateDescriptor.sampleCount = view.sampleCount
        
        do {
            try pipelineState = device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
        
        // test one cube
        primitives.append(CubePrimitive())
    }
    
    override func execute(encoder: MTLRenderCommandEncoder) {
        encoder.pushDebugGroup("primitives")
        encoder.setRenderPipelineState(pipelineState)
        for p in self.primitives {
            p.draw(encoder)
        }
        encoder.popDebugGroup()
    }
}