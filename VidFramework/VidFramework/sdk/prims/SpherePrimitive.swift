//
//  SpherePrimitive.swift
//  VidEngine
//
//  Created by David Gavilan on 8/28/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

public struct SphereDescriptor {
    public let isRegularGrid: Bool
    public let isInterior: Bool
    public let tessellationLevel: Int // only for non-regular grids
    public let widthSegments: Int // only for regular grids
    public let heightSegments: Int // only for regular grids
    public init(isInterior: Bool, tessellationLevel: Int) {
        self.isRegularGrid = false
        self.isInterior = isInterior
        self.tessellationLevel = tessellationLevel
        self.widthSegments = 0
        self.heightSegments = 0
    }
    public init(isInterior: Bool, widthSegments: Int, heightSegments: Int) {
        self.isRegularGrid = true
        self.isInterior = isInterior
        self.tessellationLevel = 0
        self.widthSegments = widthSegments
        self.heightSegments = heightSegments
    }
}

/// A 3D object that represents a sphere.
public class SpherePrimitive : Primitive {
    // this could probably be a series of flags, hasInterior & hasExterior
    fileprivate let isInterior : Bool
    
    /// @param tesselationLevel: 2: 162 vertices; 3: 642 vertices; 4: 2562 vertices
    public init(instanceCount: Int, descriptor: SphereDescriptor) {
        self.isInterior = descriptor.isInterior
        super.init(instanceCount: instanceCount)
        if descriptor.isRegularGrid {
            let ss = SubdivisionSphere(widthSegments: descriptor.widthSegments, heightSegments: descriptor.heightSegments)
            initBuffers(vertices: ss.vertices, faces: ss.faces, uvs: ss.uvs)
        }
        else {
            let ps = PlatonicSolid.createIcosahedron()
            for _ in 0..<descriptor.tessellationLevel {
                ps.subdivide()
            }
            let uvs = ps.computeTexCoordsFromSphericalProjection()
            initBuffers(vertices: ps.vertices, faces: ps.faces, uvs: uvs)
        }
    }
    
    fileprivate func initBuffers(vertices: [float3], faces: [int3], uvs: [Vec2]) {
        var triangleList = [UInt16](repeating: 0, count: faces.count * 3)
        for i in 0..<faces.count {
            // isInterior -> CW winding
            let a = isInterior ? 3 * i + 2 : 3 * i
            let b = 3 * i + 1
            let c = isInterior ? 3 * i : 3 * i + 2
            triangleList[a] = UInt16(faces[i].x)
            triangleList[b] = UInt16(faces[i].y)
            triangleList[c] = UInt16(faces[i].z)
        }
        let numIndices = faces.count * 3
        let indexBuffer = Renderer.shared.createIndexBuffer("sphere IB", elements: triangleList)
        vertexBuffer = Renderer.shared.createTexturedVertexBuffer("sphere VB", numElements: vertices.count)
        let vb = vertexBuffer.contents().assumingMemoryBound(to: TexturedVertex.self)
        for i in 0..<vertices.count {
            let x = Vec3(vertices[i])
            let n = Vec3((isInterior ? -1.0 : 1.0) * normalize(vertices[i]))
            vb[i] = TexturedVertex(position: x, normal: n, uv: uvs[i])
        }
        submeshes.append(Mesh(numIndices: numIndices, indexBuffer: indexBuffer, albedoTexture: nil))
    }
}
