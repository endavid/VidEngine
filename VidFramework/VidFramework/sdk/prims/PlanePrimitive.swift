//
//  PlanePrimitive.swift
//  VidEngine
//
//  Created by David Gavilan on 2017/05/29.
//  Copyright © 2017 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

/// A single-sided quad.
/// Default measurements:
/// * 1 squared meter
/// * centered at `(0,0,0)`
/// * on plane XZ and facing up.
public class PlanePrimitive : Primitive {
    // static properties are evaluated lazily :) device should be ready!
    fileprivate static let planeIB : MTLBuffer! = PlanePrimitive.createPlaneIndexBuffer()
    fileprivate static let planeVB : MTLBuffer! = PlanePrimitive.createPlaneVertexBuffer()
    // CCW list of triangles
    fileprivate static let triangleList : [UInt16] = [0, 2, 1, 1, 2, 3]

    public override init(numInstances: Int) {
        super.init(numInstances: numInstances)
        vertexBuffer = PlanePrimitive.planeVB
        let mesh = Mesh(numIndices: PlanePrimitive.triangleList.count, indexBuffer: PlanePrimitive.planeIB, albedoTexture: nil)
        submeshes.append(mesh)
    }

    static func createPlaneIndexBuffer() -> MTLBuffer {
        let buffer = Renderer.shared.createIndexBuffer("plane IB", elements: PlanePrimitive.triangleList)
        return buffer
    }

    static func createPlaneVertexBuffer() -> MTLBuffer {
        let buffer = Renderer.shared.createTexturedVertexBuffer("plane VB", numElements: 4)
        let vb = buffer.contents().assumingMemoryBound(to: TexturedVertex.self)
        let a = 0.5 * Vec3(-1, 0, +1)
        let b = 0.5 * Vec3(-1, 0, -1)
        let c = 0.5 * Vec3(+1, 0, +1)
        let d = 0.5 * Vec3(+1, 0, -1)
        let up = Vec3(0, +1, 0)
        vb[ 0] = TexturedVertex(position: a, normal: up, uv: Vec2(0,1))
        vb[ 1] = TexturedVertex(position: b, normal: up, uv: Vec2(0,0))
        vb[ 2] = TexturedVertex(position: c, normal: up, uv: Vec2(1,1))
        vb[ 3] = TexturedVertex(position: d, normal: up, uv: Vec2(1,0))
        return buffer
    }
}
