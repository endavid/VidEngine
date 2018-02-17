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
    fileprivate static let cubeIB : MTLBuffer! = CubePrimitive.createCubeIndexBuffer()
    fileprivate static let cubeVB : MTLBuffer! = CubePrimitive.createCubeVertexBuffer()
    // CCW list of triangles
    fileprivate static let triangleList : [UInt16] = [
        0, 1, 2, 1, 3, 2, // left
        5, 4, 6, 5, 6, 7, // right
        11, 8, 10, 9, 8, 11, // up
        13, 12, 15, 12, 14, 15, // down
        16, 18, 17, 18, 19, 17, // front
        23, 20, 21, 23, 21, 22] // back
    
    override init(numInstances: Int) {
        super.init(numInstances: numInstances)
        vertexBuffer = CubePrimitive.cubeVB
        let mesh = Mesh(numIndices: CubePrimitive.triangleList.count, indexBuffer: CubePrimitive.cubeIB, albedoTexture: nil)
        submeshes.append(mesh)
    }
    
    static func createCubeIndexBuffer() -> MTLBuffer {
        let buffer = RenderManager.sharedInstance.createIndexBuffer("cube IB", elements: CubePrimitive.triangleList)
        return buffer
    }
    
    static func createCubeVertexBuffer() -> MTLBuffer {
        let uv0 = Vec2(0, 0)
        let buffer = RenderManager.sharedInstance.createTexturedVertexBuffer("cube VB", numElements: 6 * 4)
        let vb = buffer.contents().assumingMemoryBound(to: TexturedVertex.self)
        let a = 0.5 * Vec3(-1, +1, +1)
        let b = 0.5 * Vec3(-1, +1, -1)
        let c = 0.5 * Vec3(-1, -1, +1)
        let d = 0.5 * Vec3(-1, -1, -1)
        let e = 0.5 * Vec3(+1, +1, +1)
        let f = 0.5 * Vec3(+1, +1, -1)
        let g = 0.5 * Vec3(+1, -1, +1)
        let h = 0.5 * Vec3(+1, -1, -1)
        let left = Vec3(-1, 0, 0)
        let right = Vec3(+1, 0, 0)
        let up = Vec3(0, +1, 0)
        let down = Vec3(0, -1, 0)
        let front = Vec3(0, 0, +1)
        let back = Vec3(0, 0, -1)
        vb[ 0] = TexturedVertex(position: a, normal: left, uv: uv0)
        vb[ 1] = TexturedVertex(position: b, normal: left, uv: uv0)
        vb[ 2] = TexturedVertex(position: c, normal: left, uv: uv0)
        vb[ 3] = TexturedVertex(position: d, normal: left, uv: uv0)
        vb[ 4] = TexturedVertex(position: e, normal: right, uv: uv0)
        vb[ 5] = TexturedVertex(position: f, normal: right, uv: uv0)
        vb[ 6] = TexturedVertex(position: g, normal: right, uv: uv0)
        vb[ 7] = TexturedVertex(position: h, normal: right, uv: uv0)
        vb[ 8] = TexturedVertex(position: b, normal: up, uv: uv0)
        vb[ 9] = TexturedVertex(position: f, normal: up, uv: uv0)
        vb[10] = TexturedVertex(position: a, normal: up, uv: uv0)
        vb[11] = TexturedVertex(position: e, normal: up, uv: uv0)
        vb[12] = TexturedVertex(position: c, normal: down, uv: uv0)
        vb[13] = TexturedVertex(position: g, normal: down, uv: uv0)
        vb[14] = TexturedVertex(position: d, normal: down, uv: uv0)
        vb[15] = TexturedVertex(position: h, normal: down, uv: uv0)
        vb[16] = TexturedVertex(position: a, normal: front, uv: uv0)
        vb[17] = TexturedVertex(position: e, normal: front, uv: uv0)
        vb[18] = TexturedVertex(position: c, normal: front, uv: uv0)
        vb[19] = TexturedVertex(position: g, normal: front, uv: uv0)
        vb[20] = TexturedVertex(position: f, normal: back, uv: uv0)
        vb[21] = TexturedVertex(position: h, normal: back, uv: uv0)
        vb[22] = TexturedVertex(position: d, normal: back, uv: uv0)
        vb[23] = TexturedVertex(position: b, normal: back, uv: uv0)
        return buffer
    }
}
