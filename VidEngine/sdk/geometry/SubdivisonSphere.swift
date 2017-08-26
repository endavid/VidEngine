//
//  SubdivisonSphere.swift
//  VidEngine
//
//  Created by David Gavilan on 2017/05/29.
//  Copyright © 2017 David Gavilan. All rights reserved.
//

import simd

// Better UVs than PlatonicSolids
class SubdivisionSphere {
    var vertices: [float3] = []
    var uvs: [Vec2] = []
    var faces: [int3] = []

    // size = 1 by default (radius = 0.5)
    init(widthSegments: Int, heightSegments: Int) {
        let w = max(widthSegments, 3)
        let h = max(heightSegments, 2)
        var i = 0
        var indices: [[Int32]] = []
        for y in 0...h {
            let v = Float(y) / Float(h)
            var row: [Int32] = []
            for x in 0...w {
                let u = Float(x) / Float(w)
                let sph = Spherical(r: 0.5, θ: v * .pi, φ: u * 2.0 * .pi)
                vertices.append(sph.toCartesian())
                uvs.append(Vec2(1-u,v))
                row.append(Int32(i))
                i += 1
            }
            indices.append(row)
        }
        for y in 0..<h {
            for x in 0..<w {
                let v1 = indices[y][x+1]
                let v2 = indices[y][x]
                let v3 = indices[y+1][x]
                let v4 = indices[y+1][x+1]
                if y != 0 {
                    faces.append(int3(v1, v2, v4))
                }
                if y != h-1 {
                    faces.append(int3(v2, v3, v4))
                }
            }
        }
    }
}
