//
//  CubePrimitive.swift
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

class CubePrimitive : Primitive {
    // static properties are evaluated lazily :) device should be ready!
    static let indexBuffer : MTLBuffer! = CubePrimitive.createCubeIndexBuffer()
    static let vertexBuffer : MTLBuffer! = CubePrimitive.createCubeVertexBuffer()
    
    static func createCubeIndexBuffer() -> MTLBuffer {
        // Clock-Wise: 3, 2, 6, 7, 4, 2, 0, 3, 1, 6, 5, 4, 1, 0
        let buffer = RenderManager.sharedInstance.createIndexBuffer("cube IB", elements: [2, 3, 7, 6, 5, 3, 1, 2, 0, 7, 4, 5, 0, 1]) // CCW
        return buffer
    }
    
    static func createCubeVertexBuffer() -> MTLBuffer {
        let sqrt3 : Float = 1 / sqrt(3.0)
        let uv0 = Vec2(x: 0, y: 0)
        let buffer = RenderManager.sharedInstance.createTexturedVertexBuffer("cube VB", numElements: 8)
        let vb = UnsafeMutablePointer<TexturedVertex>(buffer.contents())
        vb[0] = TexturedVertex(position: Vec3(x: 0.5, y: 0.5, z:-0.5), normal: Vec3(x: sqrt3, y: sqrt3, z:-sqrt3), uv: uv0)
        vb[1] = TexturedVertex(position: Vec3(x:-0.5, y: 0.5, z:-0.5), normal: Vec3(x:-sqrt3, y: sqrt3, z:-sqrt3), uv: uv0)
        vb[2] = TexturedVertex(position: Vec3(x: 0.5, y: 0.5, z: 0.5), normal: Vec3(x: sqrt3, y: sqrt3, z: sqrt3), uv: uv0)
        vb[3] = TexturedVertex(position: Vec3(x:-0.5, y: 0.5, z: 0.5), normal: Vec3(x:-sqrt3, y: sqrt3, z: sqrt3), uv: uv0)
        vb[4] = TexturedVertex(position: Vec3(x: 0.5, y:-0.5, z:-0.5), normal: Vec3(x: sqrt3, y:-sqrt3, z:-sqrt3), uv: uv0)
        vb[5] = TexturedVertex(position: Vec3(x:-0.5, y:-0.5, z:-0.5), normal: Vec3(x:-sqrt3, y:-sqrt3, z:-sqrt3), uv: uv0)
        vb[6] = TexturedVertex(position: Vec3(x:-0.5, y:-0.5, z: 0.5), normal: Vec3(x:-sqrt3, y:-sqrt3, z: sqrt3), uv: uv0)
        vb[7] = TexturedVertex(position: Vec3(x: 0.5, y:-0.5, z: 0.5), normal: Vec3(x: sqrt3, y:-sqrt3, z: sqrt3), uv: uv0)
        return buffer
    }
    
    override func draw(encoder: MTLRenderCommandEncoder) {
        encoder.setVertexBuffer(CubePrimitive.vertexBuffer, offset: 0, atIndex: 0)
        RenderManager.sharedInstance.setUniformBuffer(encoder, atIndex: 1)
        encoder.drawIndexedPrimitives(.TriangleStrip, indexCount: 14, indexType: .UInt16, indexBuffer: CubePrimitive.indexBuffer, indexBufferOffset: 0)
    }
}