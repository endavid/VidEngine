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
        let m = float4x4([
            scale.x * float4(1,0,0,0),
            scale.y * float4(0,1,0,0),
            scale.z * float4(0,0,1,0),
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

