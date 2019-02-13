//
//  AngleAxis.swift
//  VidFramework
//
//  Created by David Gavilan on 2019/02/13.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import simd

/// An easy-to-read representation of rotations
public struct AngleAxis: CustomStringConvertible {
    private var aa = float4(0, 0, 1, 0)
    public var angle: Float {
        get {
            return aa.w
        }
    }
    public var axis: float3 {
        get {
            return aa.xyz
        }
    }
    public var description : String {
        return "aa(angle: \(aa.w), axis: (\(aa.x), \(aa.y), \(aa.z)))"
    }
    public init() {
    }
    public init(angle: Float, axis: float3) {
        // assume that axis is already a unit vector, normalized
        aa = float4(axis.x, axis.y, axis.z, angle)
    }
}
/// rotation of a vector by an AngleAxis
public func * (aa: AngleAxis, v: float3) -> float3 {
    let q = Quaternion(aa)
    return q * v
}
