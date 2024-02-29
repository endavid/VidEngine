//
//  Triangle.swift
//  VidFramework
//
//  Created by David Gavilan on 2019/03/09.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import simd

public struct Triangle {
    public let a: simd_float3
    public let b: simd_float3
    public let c: simd_float3
    public init(a: simd_float3, b: simd_float3, c: simd_float3) {
        self.a = a
        self.b = b
        self.c = c
    }
    /// Computes normal assuming CCW for front faces
    public func getNormal() -> simd_float3 {
        let bc = c - b
        let ba = a - b
        return normalize(cross(bc, ba))
    }
}

public func * (t: Transform, triangle: Triangle) -> Triangle {
    let a = t * triangle.a
    let b = t * triangle.b
    let c = t * triangle.c
    return Triangle(a: a, b: b, c: c)
}
