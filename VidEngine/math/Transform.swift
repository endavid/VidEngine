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
    
    func toMatrix4() -> Matrix4 {
        let rm = rotation.toMatrix4()
        let m = float4x4([
            scale.x * rm[0],
            scale.y * rm[1],
            scale.z * rm[2],
            float4(position.x, position.y, position.z, 1.0)
            ])
        return Matrix4(m: m)
    }
    func inverse() -> Transform {
        return Transform(
            position: -self.position,
            scale: self.scale.inverse(),
            rotation: self.rotation.inverse())
    }
}

