//
//  Transform.swift
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import simd

public struct Transform {
    public var position = simd_float3(0, 0, 0)
    public var scale = simd_float3(1, 1, 1)
    public var rotation = Quaternion()
    
    public func toMatrix4() -> float4x4 {
        let rm = rotation.toMatrix4()
        let xx = scale.x * rm[0]
        let yy = scale.y * rm[1]
        let zz = scale.z * rm[2]
        let tt = simd_float4(position.x, position.y, position.z, 1.0)
        return float4x4([xx, yy, zz, tt])
    }
    public func inverse() throws -> Transform {
        // M = T * R * S -> M^ = S^ * R^ * T^
        // if the scale is not uniform, S^ * R^ will create
        // a shear matrix, that can be decomposed using svd,
        // S^ * R^ = U * S * V^, but not into rot * scale
        if !scale.isClose(scale.x * simd_float3(1,1,1)) {
            throw MathError.unsupported("Transforms with anisotropic scaling can't be inverted")
        }
        let r = rotation.inverse()
        let s = scale.inverse()
        let scaleMatrix = float3x3(diagonal: s)
        // verified that SR == (rotation.toMatrix3() * float3x3(diagonal: scale)).inverse
        let SR = scaleMatrix * r.toMatrix3()
        let ti = -position
        // verified that t == SR * ti
        let t = s * (r * ti)
        return Transform(rotationAndScale: SR, translation: t)
    }
    public init(position: simd_float3) {
        self.position = position
    }
    public init(position: simd_float3, scale: simd_float3) {
        self.position = position
        self.scale = scale
    }
    public init(position: simd_float3, scale: Float) {
        self.position = position
        self.scale = simd_float3(scale, scale, scale)
    }
    public init(position: simd_float3, scale: simd_float3, rotation: Quaternion) {
        self.position = position
        self.scale = scale
        self.rotation = rotation
    }
    public init(rotationAndTranslation matrix: float4x4) {
        let (c0, c1, c2, c3) = matrix.columns
        position = simd_float3(c3.x, c3.y, c3.z)
        scale = simd_float3(1, 1, 1)
        rotation = Quaternion(float3x3(c0.xyz, c1.xyz, c2.xyz))
    }
    public init(rotationAndScale matrix: float3x3, translation: simd_float3) {
        position = translation
        // https://math.stackexchange.com/a/1463487
        // only works if there's no shear
        let (a, b, c) = matrix.columns
        scale = simd_float3(length(a), length(b), length(c))
        //let (u, s, v) = svd(matrix: matrix)
        rotation = Quaternion(float3x3(a/scale.x, b/scale.y, c/scale.z))
    }
    public init(transform matrix: float4x4) {
        let (c0, c1, c2, c3) = matrix.columns
        let t = simd_float3(c3.x, c3.y, c3.z)
        let RS = float3x3(c0.xyz, c1.xyz, c2.xyz)
        self.init(rotationAndScale: RS, translation: t)
    }
    
    public init() {
    }
    public func rotate(direction: simd_float3) -> simd_float3 {
        // parenthesis are important! Otherwise the scale
        // vector will be rotated, and then transformed!
        return normalize(rotation * (scale * direction))
    }
}

public func * (t1: Transform, t2: Transform) -> Transform {
    let q = t1.rotation * t2.rotation
    let s = t1.scale * t2.scale
    let x = t1.scale * (t1.rotation * t2.position) + t1.position
    return Transform(position: x, scale: s, rotation: q)
}

public func * (t: Transform, v: simd_float3) -> simd_float3 {
    return t.position + t.rotation * (t.scale * v)
}
