//
//  Shaders.metal
//
//  Created by David Gavilan on 3/31/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

#include <metal_stdlib>
#include "ShaderCommon.h"
//#include "ShaderMath.h"

using namespace metal;

struct VertexInOut {
    float4  position [[position]];
    float4  color;
};

struct TexturedVertex
{
    packed_float3 position [[attribute(0)]];
    packed_float3 normal [[attribute(1)]];
    packed_float2 texCoords [[attribute(2)]];
};

vertex VertexInOut passVertexRaindrop(uint vid [[ vertex_id ]],
                                      constant packed_float4* position  [[ buffer(0) ]])
{
    VertexInOut outVertex;
    
    float4 posAndVelocity = position[vid];
    outVertex.position = float4(posAndVelocity.xy, 0, 1);
    outVertex.color    = float4(vid % 2, 1, 1, 0.1 + 0.5 * (vid % 2));
    return outVertex;
};

vertex VertexInOut passGeometry(uint vid [[ vertex_id ]],
                                uint iid [[ instance_id ]],
                                constant TexturedVertex* vdata [[ buffer(0) ]],
                                constant Uniforms& uniforms  [[ buffer(1) ]],
                                constant PerInstanceUniforms* perInstanceUniforms [[ buffer(2) ]])
{
    VertexInOut outVertex;
    PerInstanceUniforms iu = perInstanceUniforms[iid];
    float4x4 m = uniforms.projectionMatrix * uniforms.viewMatrix * iu.modelMatrix;
    TexturedVertex v = vdata[vid];
    outVertex.position = m * float4(v.position, 1.0);
    outVertex.color = float4(v.normal, 1);
    return outVertex;
}

fragment half4 passThroughFragment(VertexInOut inFrag [[stage_in]])
{
    return half4(inFrag.color);
};
