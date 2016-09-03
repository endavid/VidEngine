//
//  ModelPrimitive.swift
//  VidEngine
//
//  Created by David Gavilan on 9/1/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

class ModelPrimitive : Primitive {
    private var indexBuffer : MTLBuffer!
    private var vertexBuffer : MTLBuffer!
    private var numIndices : Int = 0

    init(vertices: [TexturedVertex], triangles: [UInt16]) {
        super.init(priority: 0, numInstances: 1)
        initBuffers(vertices, triangles: triangles)
    }
    
    init(assetName: String, priority: Int, numInstances: Int) {
        super.init(priority: priority, numInstances: numInstances)
    }
    
    func initBuffers(vertices: [TexturedVertex], triangles: [UInt16]) {
        indexBuffer = RenderManager.sharedInstance.createIndexBuffer("model IB", elements: triangles)
        vertexBuffer = RenderManager.sharedInstance.createTexturedVertexBuffer("model VB", numElements: vertices.count)
        numIndices = triangles.count
        let vb = UnsafeMutablePointer<TexturedVertex>(vertexBuffer.contents())
        for i in 0..<vertices.count {
            vb[i] = vertices[i]
        }
    }

    override func draw(encoder: MTLRenderCommandEncoder) {
        encoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
        RenderManager.sharedInstance.setUniformBuffer(encoder, atIndex: 1)
        encoder.setVertexBuffer(self.uniformBuffer, offset: 0, atIndex: 2)
        encoder.drawIndexedPrimitives(.Triangle, indexCount: numIndices, indexType: .UInt16, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: transforms.count)
    }
}
