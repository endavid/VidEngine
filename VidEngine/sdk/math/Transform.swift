//
//  Transform.swift
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import simd

struct Transform {
    var position = float3(0, 0, 0)
    var scale = float3(1, 1, 1)
    var rotation = Quaternion()
    
    func toMatrix4() -> float4x4 {
        let rm = rotation.toMatrix4()
        let xx = scale.x * rm[0]
        let yy = scale.y * rm[1]
        let zz = scale.z * rm[2]
        let tt = float4(position.x, position.y, position.z, 1.0)
        return float4x4([xx, yy, zz, tt])
    }
    func inverse() -> Transform {
        return Transform(
            position: -self.position,
            scale: self.scale.inverse(),
            rotation: self.rotation.inverse())
    }
}

