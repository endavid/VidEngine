//
//  GfxData.swift
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import simd
import Metal

struct TexturedVertex {
    var position : Vec3
    var normal : Vec3
    var uv : Vec2

    static func createVertexDescriptor() -> MTLVertexDescriptor {
        let vertexDesc = MTLVertexDescriptor()
        vertexDesc.attributes[0].format = .float3
        vertexDesc.attributes[0].offset = 0
        vertexDesc.attributes[0].bufferIndex = 0
        vertexDesc.attributes[1].format = .float3
        vertexDesc.attributes[1].offset = MemoryLayout<Vec3>.size
        vertexDesc.attributes[1].bufferIndex = 0
        vertexDesc.attributes[2].format = .float2
        vertexDesc.attributes[2].offset = MemoryLayout<Vec3>.size * 2
        vertexDesc.attributes[2].bufferIndex = 0
        vertexDesc.layouts[0].stepFunction = .perVertex
        vertexDesc.layouts[0].stride = MemoryLayout<TexturedVertex>.size
        return vertexDesc
    }
}

struct ColoredUnlitTexturedVertex {
    var position : Vec3
    var uv : Vec2
    var color : UInt32

    static func createVertexDescriptor() -> MTLVertexDescriptor {
        let vertexDesc = MTLVertexDescriptor()
        vertexDesc.attributes[0].format = .float3
        vertexDesc.attributes[0].offset = 0
        vertexDesc.attributes[0].bufferIndex = 0
        vertexDesc.attributes[1].format = .float2
        vertexDesc.attributes[1].offset = MemoryLayout<Vec3>.size
        vertexDesc.attributes[1].bufferIndex = 0
        vertexDesc.attributes[2].format = .uchar4Normalized
        vertexDesc.attributes[2].offset = MemoryLayout<Vec3>.size + MemoryLayout<Vec2>.size
        vertexDesc.attributes[2].bufferIndex = 0
        vertexDesc.layouts[0].stepFunction = .perVertex
        vertexDesc.layouts[0].stride = MemoryLayout<ColoredUnlitTexturedVertex>.size
        return vertexDesc
    }
}

public struct PerInstanceUniforms {
    var transform : Transform
    var material : Material
}
