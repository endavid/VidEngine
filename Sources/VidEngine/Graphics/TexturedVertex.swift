//
//  TexturedVertex.swift
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
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
    var position: Vec3
    var uv: Vec2
    // can't use float4 here, because then it automatically aligns everything
    // in the struct, and the size of this becomes 48 instead of 36...
    // GPU mem layout expects 36 bytes of data.
    var color: Vec4
    
    static func createVertexDescriptor() -> MTLVertexDescriptor {
        let vertexDesc = MTLVertexDescriptor()
        vertexDesc.attributes[0].format = .float3
        vertexDesc.attributes[0].offset = 0
        vertexDesc.attributes[0].bufferIndex = 0
        vertexDesc.attributes[1].format = .float2
        vertexDesc.attributes[1].offset = MemoryLayout<Vec3>.size
        vertexDesc.attributes[1].bufferIndex = 0
        vertexDesc.attributes[2].format = .float4
        vertexDesc.attributes[2].offset = MemoryLayout<Vec3>.size + MemoryLayout<Vec2>.size
        vertexDesc.attributes[2].bufferIndex = 0
        vertexDesc.layouts[0].stepFunction = .perVertex
        vertexDesc.layouts[0].stride = MemoryLayout<ColoredUnlitTexturedVertex>.size
        return vertexDesc
    }
}

