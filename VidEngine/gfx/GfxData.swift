//
//  GfxData.swift
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import simd

struct Vec3 {
    let x : Float
    let y : Float
    let z : Float
}

struct Vec2 {
    let x : Float
    let y : Float
}

struct TexturedVertex {
    let position : Vec3
    let normal : Vec3
    let uv : Vec2
}

struct PerInstanceUniforms {
    let modelMatrix : float4x4
}