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
        return Matrix4.identity
    }
}

func Inverse(t: Transform) -> Transform {
    return Transform(
        position: -t.position,
        scale: Inverse(t.scale),
        rotation: Inverse(t.rotation))
}