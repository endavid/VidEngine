//
//  PlanePrimitive.swift
//  VidEngine
//
//  Created by David Gavilan Ruiz on 20/06/2025.
//
import Metal
import MetalKit

/// A single-sided quad.
/// Default measurements:
/// * 1 squared meter
/// * centered at `(0,0,0)`
/// * on plane XZ and facing up.
public class PlanePrimitive: Primitive {
    private static var planeIB: MTLBuffer?
    private static var planeVB: MTLBuffer?
    // CCW list of triangles
    private static let triangleList : [UInt16] = [0, 2, 1, 1, 2, 3]
    
    // used to compute UV scaling
    var gridSizeMeters: Float = 0.1 // 10 cm
    
    public override init(instanceCount: Int) {
        super.init(instanceCount: instanceCount)
        submeshes.append(Mesh())
    }
    
    override func initBuffers(_ renderer: Renderer) {
        super.initBuffers(renderer)
        // initialize these buffers only once, because we
        // want to share them with all the cubes
        if PlanePrimitive.planeIB == nil {
            PlanePrimitive.planeIB = PlanePrimitive.createPlaneIndexBuffer(renderer)
        }
        if PlanePrimitive.planeVB == nil {
            PlanePrimitive.planeVB = PlanePrimitive.createPlaneVertexBuffer(renderer)
        }
        if vertexBuffer == nil {
            vertexBuffer = PlanePrimitive.planeVB
            submeshes[0].numIndices = PlanePrimitive.triangleList.count
            submeshes[0].indexBuffer = PlanePrimitive.planeIB
        }
    }
    
    static func createPlaneIndexBuffer(_ renderer: Renderer) -> MTLBuffer {
        let buffer = renderer.createIndexBuffer("plane IB", elements: PlanePrimitive.triangleList)
        return buffer
    }
    
    static func createPlaneVertexBuffer(_ renderer: Renderer) -> MTLBuffer {
        let buffer = renderer.createTexturedVertexBuffer("plane VB", numElements: 4)
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
    
    override func getTriangles() -> [Triangle] {
        let t1 = Triangle(a: simd_float3(0.5, 0, -0.5), b: simd_float3(-0.5, 0, -0.5), c: simd_float3(-0.5, 0, 0.5))
        let t2 = Triangle(a: simd_float3(-0.5, 0, 0.5), b: simd_float3(0.5, 0, 0.5), c: simd_float3(0.5, 0, -0.5))
        return [t1, t2]
    }
}
