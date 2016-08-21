//
//  Quaternion.swift
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import simd

struct Quaternion : CustomStringConvertible {
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
    func toString() -> String {
        return description
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
}
