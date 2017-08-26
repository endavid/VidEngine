//
//  Quaternion.swift
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import simd

extension float4 : Equatable {

    @inline(__always)
    public static func ==(lhs: float4, rhs: float4) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z && lhs.w == rhs.w
    }
}

struct Quaternion : CustomStringConvertible, Equatable {
    var q = float4(0, 0, 0, 1) /// xyz: imaginary part; w: real part
    var w : Float {
        get {
            return q.w
        }
    }
    var v : float3 {
        get {
            return float3(q.x, q.y, q.z)
        }
    }
    var description : String {
        return "q(w: \(q.w), v: (\(q.x), \(q.y), \(q.z)))"
    }

    init() {

    }

    init(w: Float, v: float3) {
        q = float4(v.x, v.y, v.z, w)
    }
    func conjugate() -> Quaternion {
        return Quaternion(w: self.w, v: -self.v)
    }

    func inverse() -> Quaternion {
        // assume it's a unit quaternion, so just Conjugate
        return conjugate()
    }
    // Can be used the determine Quaternion neighbourhood
    func dotQ(_ q: Quaternion) -> Float {
        return dot(q.v, v) + self.w * q.w
    }
    /// Returns a rotation matrix (column major, p' = M * p)
    func toMatrix4() -> float4x4 {
        let w2 = w * w
        let x2 = q.x * q.x
        let y2 = q.y * q.y
        let z2 = q.z * q.z
        var m = float4x4()
        m[0,0] = w2 + x2 - y2 - z2
        m[1,0] = 2*q.x*q.y - 2*w*q.z
        m[2,0] = 2*q.x*q.z + 2*w*q.y
        m[0,1] = 2*q.x*q.y + 2*w*q.z
        m[1,1] = w2 - x2 + y2 - z2
        m[2,1] = 2*q.y*q.z - 2*w*q.x
        m[0,2] = 2*q.x*q.z - 2*w*q.y
        m[1,2] = 2*q.y*q.z + 2*w*q.x
        m[2,2] = w2 - x2 - y2 + z2
        m[3,3] = w2 + x2 + y2 + z2 // = 1 if unit quaternion
        return m
    }

    static func ==(lhs: Quaternion, rhs: Quaternion) -> Bool {
        return lhs.q == rhs.q
    }

    static func createRotationAxis(_ angle: Float, unitVector: float3) -> Quaternion {
        return Quaternion(w: cosf(0.5 * angle), v: sinf(0.5 * angle) * unitVector)
    }
    static func createRotation(start: float3, end: float3) -> Quaternion {
        let up = float3(start.x, start.z, start.y)
        return createRotation(start: start, end: end, up: up)
    }
    static func createRotation(start: float3, end: float3, up: float3) -> Quaternion {
        if end.isClose(start, epsilon: 0.01) { // no rotation
            return Quaternion()
        }
        if end.isClose(-start, epsilon: 0.01) { // opposite vectors
            return Quaternion.createRotationAxis(.pi, unitVector: up)
        }
        let angle = acosf(dot(start, end))
        let axis = normalize(cross(start, end))
        return Quaternion.createRotationAxis(angle, unitVector: axis)
    }

    // -----------------------------------------------------------
    static func + (a: Quaternion, b: Quaternion) -> Quaternion {
        return Quaternion(w: a.w + b.w, v: a.v + b.v)
    }

    static func * (a: Quaternion, scalar: Float) -> Quaternion {
        return Quaternion(w: a.w * scalar, v: a.v * scalar)
    }

    static func * (a: Quaternion, b: Quaternion) -> Quaternion {
        let scalar = a.w * b.w - dot(a.v, b.v)
        let v = cross(a.v, b.v) + a.w * b.v + b.w * a.v
        return Quaternion(w: scalar, v: v)
    }

    /// rotation of a vector by a UNIT quaternion
    static func * (q: Quaternion, v: float3) -> float3 {
        let p = q * Quaternion(w: 0, v: v) * q.inverse()
        return p.v
    }
}


// -----------------------------------------------------------
/// Linear interpolation
func Lerp(_ start: Quaternion, end: Quaternion, t: Float) -> Quaternion {
    return start * (1-t) + end * t
}
// -----------------------------------------------------------
/// Spherical linear interpolation
func Slerp(_ start: Quaternion, end: Quaternion, t: Float) -> Quaternion {
    var w1 : Float
    var w2 : Float

    let cosTheta = start.dotQ(end)
    let theta    = acosf(cosTheta)
    let sinTheta = sinf(theta)

    if( sinTheta > 0.001 ) {
        w1 = sinf((1.0-t)*theta) / sinTheta
        w2 = sinf(t*theta) / sinTheta
    } else {
        // CQuat a ~= CQuat b
        w1 = 1.0 - t
        w2 = t
    }
    return start*w1 + end*w2
}

