//
//  Matrix.swift
//
//  Created by David Gavilan on 2/10/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//

import Foundation
import Accelerate
import simd

/* 4x4 Matrix, Column-major
 * m[column, row]
 * m[column] returns a Vector4 column
 */
struct Matrix4 {
    static let identity : Matrix4 = Matrix4(
        m: float4x4([
            float4(1, 0, 0, 0),
            float4(0, 1, 0, 0),
            float4(0, 0, 1, 0),
            float4(0, 0, 0, 1)]))
    
    var m = float4x4()
    
    
    subscript(column: Int, row: Int) -> Float {
        get {
            return self[column][row]
        }
        set {
            self[column][row] = newValue
        }
    }
    subscript(column: Int) -> float4 {
        get {
            return m[column]
        }
        set {
            m[column] = newValue
        }
    }
    
    static func CreateFrustum(left left: Float,right: Float,bottom: Float,top: Float,near: Float,far: Float) -> Matrix4
    {
        let m = float4x4([
            float4(2 * near / (right - left), 0, 0, 0),
            float4(0, 2 * near / (top - bottom), 0, 0),
            float4((right + left) / (right - left), (top + bottom) / (top - bottom), -(far + near) / (far - near), -1),
            float4(0, 0, -2 * far * near / (far - near), 0)]
        )
        return Matrix4(m: m)
    }
    static func Perspective(fov fov: Float,near: Float, far: Float, aspectRatio: Float) -> Matrix4 {
        let size = near * tanf(0.5*DegToRad(fov))
        return Matrix4.CreateFrustum(left: -size, right: size,
                                     bottom: -size / aspectRatio, top: size / aspectRatio,
                                     near: near, far: far)
    }
    // Inverses
    static func CreateFrustumInverse(left left: Float,right: Float,bottom: Float,top: Float,near: Float,far: Float) -> Matrix4
    {
        let invNear = 0.5 / near;
        let invNearFar = invNear / far
        let m = float4x4([
            float4((right - left) * invNear, 0, 0, 0),
            float4(0, (top - bottom) * invNear, 0, 0),
            float4(0, 0, 0, (near - far) * invNearFar),
            float4((right + left) * invNear, (top + bottom) * invNear, -1, (far + near) * invNearFar)]
        )
        return Matrix4(m: m)
    }
    static func PerspectiveInverse(fov fov: Float,near: Float, far: Float, aspectRatio: Float) -> Matrix4 {
        let size = near * tanf(0.5*DegToRad(fov))
        return Matrix4.CreateFrustumInverse(left: -size, right: size,
                                     bottom: -size / aspectRatio, top: size / aspectRatio,
                                     near: near, far: far)
    }    
}

// -----------------------------------------------------------
// operators
// -----------------------------------------------------------

func + (left: Matrix4, right: Matrix4) -> Matrix4 {
    return Matrix4(m: left.m + right.m)
}

func * (m: Matrix4, v: float4) -> float4 {
    return m.m * v
}

func * (v: float4, m: Matrix4) -> float4 {
    return v * m.m
}

func * (a: Matrix4, b: Matrix4) -> Matrix4 {
    return Matrix4(m: a.m * b.m)
}
