//
//  Transform.swift
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import simd

public struct Transform {
    public var position = float3(0, 0, 0)
    public var scale = float3(1, 1, 1)
    public var rotation = Quaternion()
    
    public func toMatrix4() -> float4x4 {
        let rm = rotation.toMatrix4()
        let xx = scale.x * rm[0]
        let yy = scale.y * rm[1]
        let zz = scale.z * rm[2]
        let tt = float4(position.x, position.y, position.z, 1.0)
        return float4x4([xx, yy, zz, tt])
    }
    public func inverse() -> Transform {
        let r = rotation.inverse()
        let s = scale.inverse()
        return Transform(
            position: r * (s * -self.position),
            scale: s,
            rotation: r)
    }
    public init(position: float3, scale: float3, rotation: Quaternion) {
        self.position = position
        self.scale = scale
        self.rotation = rotation
    }
    public init() {
    }
}

public func * (t1: Transform, t2: Transform) -> Transform {
    let q = t1.rotation * t2.rotation
    let s = t1.scale * t2.scale
    let x = t1.scale * (t1.rotation * t2.position) + t1.position
    return Transform(position: x, scale: s, rotation: q)
}

public func * (t: Transform, v: float3) -> float3 {
    return t.position + t.rotation * (t.scale * v)
}
