//
//  Quaternion.swift
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import simd

public struct Quaternion : CustomStringConvertible {
    public var q = float4(0, 0, 0, 1) /// xyz: imaginary part; w: real part
    public var w : Float {
        get {
            return q.w
        }
    }
    public var v : float3 {
        get {
            return float3(q.x, q.y, q.z)
        }
    }
    public var description : String {
        return "q(w: \(q.w), v: (\(q.x), \(q.y), \(q.z)))"
    }
    public init() {
    }
    public init(w: Float, v: float3) {
        q = float4(v.x, v.y, v.z, w)
    }
    public func conjugate() -> Quaternion {
        return Quaternion(w: self.w, v: -self.v)
    }
    public func inverse() -> Quaternion {
        // assume it's a unit quaternion, so just Conjugate
        return conjugate()
    }
    // Can be used the determine Quaternion neighbourhood
    func dotQ(_ q: Quaternion) -> Float {
        return dot(q.v, self.v) + self.w * q.w
    }
    /// Returns a rotation matrix (column major, p' = M * p)
    public func toMatrix4() -> float4x4 {
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
    
    
    public static func createRotationAxis(_ angle: Float, unitVector: float3) -> Quaternion {
        return Quaternion(w: cosf(0.5 * angle), v: sinf(0.5 * angle) * unitVector)
    }
    public static func createRotation(start: float3, end: float3) -> Quaternion {
        let up = float3(start.x, start.z, start.y)
        return createRotation(start: start, end: end, up: up)
    }
    public static func createRotation(start: float3, end: float3, up: float3) -> Quaternion {
        if end.isClose(start, epsilon: 0.01) { // no rotation
            return Quaternion()
        }
        if end.isClose(-start, epsilon: 0.01) { // opposite vectors
            return Quaternion.createRotationAxis(PI, unitVector: up)
        }
        let angle = acosf(dot(start, end))
        let axis = normalize(cross(start, end))
        return Quaternion.createRotationAxis(angle, unitVector: axis)
    }
    public static func fromMatrix(_ m: float3x3) -> Quaternion {
        let (cx, cy, cz) = m.columns
        let angle = acos((cx.x + cy.y + cz.z - 1.0) / 2.0)
        var axis = float3(0, 0, 1)
        if !IsClose(angle, 0) {
            let d = float3(
                cz.y - cy.z,
                cx.z - cz.x,
                cy.x - cx.y)
            let dd = length(d)
            if (!IsClose(dd, 0))
            {
                axis = normalize(d)
            }
        }
        return createRotationAxis(angle, unitVector: axis)
    }
}

// -----------------------------------------------------------
public func + (a: Quaternion, b: Quaternion) -> Quaternion {
    return Quaternion(w: a.w + b.w, v: a.v + b.v)
}
public func * (a: Quaternion, scalar: Float) -> Quaternion {
    return Quaternion(w: a.w * scalar, v: a.v * scalar)
}
public func * (a: Quaternion, b: Quaternion) -> Quaternion {
    let scalar = a.w * b.w - dot(a.v, b.v)
    let v = cross(a.v, b.v) + a.w * b.v + b.w * a.v
    return Quaternion(w: scalar, v: v)
}
/// rotation of a vector by a UNIT quaternion
public func * (q: Quaternion, v: float3) -> float3 {
    let p = q * Quaternion(w: 0, v: v) * q.inverse()
    return p.v
}
// -----------------------------------------------------------
/// Linear interpolation
public func Lerp(_ start: Quaternion, end: Quaternion, t: Float) -> Quaternion {
    return start * (1-t) + end * t
}
// -----------------------------------------------------------
/// Spherical linear interpolation
public func Slerp(_ start: Quaternion, end: Quaternion, t: Float) -> Quaternion {
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

