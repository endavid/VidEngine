//
//  SpherePrimitive.swift
//  VidEngine
//
//  Created by David Gavilan on 8/28/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

class SpherePrimitive : Primitive {
    private var indexBuffer : MTLBuffer!
    private var vertexBuffer : MTLBuffer!
    private var numIndices : Int = 0
    let uniformBuffer : MTLBuffer!
    
    /// @param tesselationLevel: 2: 162 vertices; 3: 642 vertices; 4: 2562 vertices
    init(priority: Int, numInstances: Int, tessellationLevel: Int) {
        uniformBuffer = RenderManager.sharedInstance.createTransformsBuffer("sphereUniforms", numElements: RenderManager.NumSyncBuffers * numInstances)
        super.init(priority: priority, numInstances: numInstances)
        initBuffers(tessellationLevel)
    }
    
    private func initBuffers(tessellationLevel: Int) {
        let ps = PlatonicSolid.createIcosahedron()
        for _ in 0..<tessellationLevel {
            ps.subdivide()
        }
        var triangleList = [UInt16](count: ps.faces.count * 3, repeatedValue: 0)
        for i in 0..<ps.faces.count {
            triangleList[3 * i] = UInt16(ps.faces[i].x)
            triangleList[3 * i + 1] = UInt16(ps.faces[i].y)
            triangleList[3 * i + 2] = UInt16(ps.faces[i].z)
        }
        numIndices = ps.faces.count * 3
        indexBuffer = RenderManager.sharedInstance.createIndexBuffer("sphere IB", elements: triangleList)
        vertexBuffer = RenderManager.sharedInstance.createTexturedVertexBuffer("sphere VB", numElements: ps.vertices.count)
        let vb = UnsafeMutablePointer<TexturedVertex>(vertexBuffer.contents())
        for i in 0..<ps.vertices.count {
            let uv = Vec2(0, 0)
            let x = Vec3(ps.vertices[i])
            let n = Vec3(normalize(ps.vertices[i]))
            vb[i] = TexturedVertex(position: x, normal: n, uv: uv)
        }
    }
    
    override func draw(encoder: MTLRenderCommandEncoder) {
        encoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
        RenderManager.sharedInstance.setUniformBuffer(encoder, atIndex: 1)
        encoder.setVertexBuffer(self.uniformBuffer, offset: 0, atIndex: 2)
        encoder.drawIndexedPrimitives(.Triangle, indexCount: numIndices, indexType: .UInt16, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: transforms.count)
    }
    
    override func updateBuffers(syncBufferIndex: Int) {
        let uniformB = uniformBuffer.contents()
        let uniformData = UnsafeMutablePointer<Float>(uniformB +  sizeof(Transform) * transforms.count * syncBufferIndex)
        memcpy(uniformData, &transforms, sizeof(Transform) * transforms.count)
    }
}