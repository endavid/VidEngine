//
//  Vector.swift
//
//  Created by David Gavilan on 2/7/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//

import simd

public extension float3 {
    init(_ v: Vec3) {
        self.init(v.x, v.y, v.z)
    }
    func inverse() -> float3 {
        return float3( x: fabsf(self.x)>0 ? 1/self.x : 0,
                       y: fabsf(self.y)>0 ? 1/self.y : 0,
                       z: fabsf(self.z)>0 ? 1/self.z : 0)
    }
    /// similar vectors
    func isClose(_ v: float3, epsilon: Float = 0.0001) -> Bool {
        let diff = self - v
        return IsClose(length_squared(diff), 0, epsilon: epsilon * epsilon)
    }
    /// Rounds to decimal places value
    func rounded(toPlaces places:Int) -> float3 {
        return float3(
            self.x.rounded(toPlaces: places),
            self.y.rounded(toPlaces: places),
            self.z.rounded(toPlaces: places))
    }
    /// Check if is within the 0..1 bounds
    func inUnitCube() -> Bool {
        return self.x >= 0 && self.x <= 1 && self.y >= 0 && self.y <= 1 && self.z >= 0 && self.z <= 1
    }
}

public extension float4 {
    var xyz: float3 {
        get {
            return float3(x, y, z)
        }
    }
}

public struct Vec4 {
    let x : Float
    let y : Float
    let z : Float
    let w : Float
    init(_ x: Float, _ y: Float, _ z: Float, _ w: Float) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
    init(_ v: float4) {
        self.x = v.x
        self.y = v.y
        self.z = v.z
        self.w = v.w
    }
}

/// 3-dimensional vector that's smaller than a float3
/// `sizeof(float3) = 16`!! `sizeof(Vec3) = 12`
public struct Vec3 {
    public static let zero = Vec3(0, 0, 0)
    let x : Float
    let y : Float
    let z : Float
    subscript(row: Int) -> Float {
        get {
            return row == 0 ? x : row == 1 ? y : z
        }
    }
    public init(_ x: Float, _ y: Float, _ z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
    public init(_ v: float3) {
        self.x = v.x
        self.y = v.y
        self.z = v.z
    }
}

public struct Vec2 {
    public static let zero = Vec2(0, 0)
    let x : Float
    let y : Float
    init(_ x: Float, _ y: Float) {
        self.x = x
        self.y = y
    }
}

func * (v: Vec3, f: Float) -> Vec3 {
    return Vec3(v.x * f, v.y * f, v.z * f)
}
func * (f: Float, v: Vec3) -> Vec3 {
    return v * f
}
func + (v0: Vec3, v1: Vec3) -> Vec3 {
    return Vec3(v0.x + v1.x, v0.y + v1.y, v0.z + v1.z)
}
