//
//  GfxData.swift
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import simd

struct TexturedVertex {
    var position : Vec3
    var normal : Vec3
    var uv : Vec2
}

struct ColoredUnlitTexturedVertex {
    var position : Vec3
    var uv : Vec2
    var color : UInt32
}

struct PerInstanceUniforms {
    var transform : Transform
    var material : Material
}
