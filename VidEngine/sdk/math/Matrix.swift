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

    static let identity = float4x4(matrix_identity_float4x4)

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
}
