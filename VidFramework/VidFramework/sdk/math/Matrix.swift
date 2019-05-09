//
//  Matrix.swift
//
//  Created by David Gavilan on 2/10/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//

import Foundation
import Accelerate
import simd

// column-major
public extension float4x4 {
    static let identity = float4x4([
        float4(1,0,0,0),
        float4(0,1,0,0),
        float4(0,0,1,0),
        float4(0,0,0,1)
    ])
    static func createFrustum(left: Float,right: Float,bottom: Float,top: Float,near: Float,far: Float) -> float4x4
    {
        let m = float4x4([
            float4(2 * near / (right - left), 0, 0, 0),
            float4(0, 2 * near / (top - bottom), 0, 0),
            float4((right + left) / (right - left), (top + bottom) / (top - bottom), -(far + near) / (far - near), -1),
            float4(0, 0, -2 * far * near / (far - near), 0)]
        )
        return m
    }
    static func perspective(fov: Float,near: Float, far: Float, aspectRatio: Float) -> float4x4 {
        let size = near * tanf(0.5*DegToRad(fov))
        return float4x4.createFrustum(left: -size, right: size,
                                     bottom: -size / aspectRatio, top: size / aspectRatio,
                                     near: near, far: far)
    }
    // Inverses
    static func createFrustumInverse(left: Float,right: Float,bottom: Float,top: Float,near: Float,far: Float) -> float4x4
    {
        let invNear = 0.5 / near;
        let invNearFar = invNear / far
        let m = float4x4([
            float4((right - left) * invNear, 0, 0, 0),
            float4(0, (top - bottom) * invNear, 0, 0),
            float4(0, 0, 0, (near - far) * invNearFar),
            float4((right + left) * invNear, (top + bottom) * invNear, -1, (far + near) * invNearFar)]
        )
        return m
    }
    static func perspectiveInverse(fov: Float,near: Float, far: Float, aspectRatio: Float) -> float4x4 {
        let size = near * tanf(0.5*DegToRad(fov))
        return float4x4.createFrustumInverse(left: -size, right: size,
                                            bottom: -size / aspectRatio, top: size / aspectRatio,
                                            near: near, far: far)
    }
    var upper3x3: float3x3 {
        get {
            let (c0, c1, c2, _) = columns
            return float3x3(c0.xyz, c1.xyz, c2.xyz)
        }
    }
    init(rowMajorElements v: [Float]) {
        let col0 = float4(v[0], v[4], v[8], v[12])
        let col1 = float4(v[1], v[5], v[9], v[13])
        let col2 = float4(v[2], v[6], v[10], v[14])
        let col3 = float4(v[3], v[7], v[11], v[15])
        self.init(col0, col1, col2, col3)
    }
}
