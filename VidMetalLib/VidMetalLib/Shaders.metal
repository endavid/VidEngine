//
//  Shaders.metal
//
//  Created by David Gavilan on 3/31/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

#include <metal_stdlib>
#include "ShaderCommon.h"
#include "ShaderMath.h"

using namespace metal;

struct ColorParams {
    float4x4 transform;
};


vertex VertexInOut passThrough2DVertex(uint vid [[ vertex_id ]],
                                     constant packed_float4* vdata [[ buffer(0) ]])
{
    VertexInOut outVertex;
    float4 xyuv = vdata[vid];
    outVertex.position = float4(xyuv.xy, 0, 1);
    outVertex.color = float4(1,1,1,1);
    outVertex.uv = xyuv.zw;
    return outVertex;
}

vertex VertexInOut passGeometry(uint vid [[ vertex_id ]],
                                uint iid [[ instance_id ]],
                                constant TexturedVertex* vdata [[ buffer(0) ]],
                                constant Uniforms& uniforms  [[ buffer(1) ]],
                                constant Transform* perInstanceUniforms [[ buffer(2) ]])
{
    VertexInOut outVertex;
    Transform t = perInstanceUniforms[iid];
    TexturedVertex v = vdata[vid];
    float4 viewPos = uniforms.viewMatrix * float4(t * v.position, 1.0);
    outVertex.position = uniforms.projectionMatrix * viewPos;
    outVertex.uv = float2(0,0);
    outVertex.color = float4(0.5 * v.normal + 0.5, 1);
    return outVertex;
}

fragment half4 passThroughFragment(VertexInOut inFrag [[stage_in]])
{
    return half4(inFrag.color);
};

fragment half4 passThroughTexturedFragment(
    VertexInOut inFrag [[stage_in]],
    texture2d<float> tex [[ texture(0) ]])
{
    float4 texColor = tex.sample(linearSampler, inFrag.uv);
    float4 out = texColor * inFrag.color;
    return half4(out);
}

fragment half4 passLinearTexturedFragment(
    VertexInOut inFrag [[stage_in]],
    texture2d<float> tex [[ texture(0) ]],
    constant ColorParams& params [[ buffer(0) ]])
{
    float4 texColor = tex.sample(linearSampler, inFrag.uv);
    float4 out = texColor * inFrag.color;
    out = params.transform * out;
    return half4(out);
}

// Converts the texture to linear RGB manually
fragment half4 passSrgbTexturedFragment(
    VertexInOut inFrag [[stage_in]],
    texture2d<float> tex [[ texture(0) ]],
    constant ColorParams& params [[ buffer(0) ]])
{
    float4 texColor = tex.sample(linearSampler, inFrag.uv);
    texColor = normalizedSrgbToLinearRgb(texColor);
    float4 out = texColor * inFrag.color;
    out = params.transform * out;
    return half4(out);
}

