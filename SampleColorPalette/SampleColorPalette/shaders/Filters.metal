//
//  Filters.metal
//  SampleColorPalette
//
//  Created by David Gavilan on 2018/02/27.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
constexpr sampler linearSampler(coord::normalized, filter::linear, address::repeat);

struct VertexInOut {
    float4  position [[position]];
    float4  color;
    float2  uv;
};

struct Uniforms {
    float4x4 colorTransform;
};

float4 linearRgbToNormalizedSrgb(float4 color);

vertex VertexInOut passThrough2DVertex(
    uint vid [[ vertex_id ]],
   constant packed_float4* vdata [[ buffer(0) ]])
{
    VertexInOut outVertex;
    float4 xyuv = vdata[vid];
    outVertex.position = float4(xyuv.xy, 0, 1);
    outVertex.color = float4(1,1,1,1);
    outVertex.uv = xyuv.zw;
    return outVertex;
}

fragment half4 passColorTransformFragment(
    VertexInOut inFrag [[stage_in]],
    texture2d<float> tex [[ texture(0) ]],
    constant Uniforms& uniforms [[ buffer(0) ]])
{
    float4 texColor = tex.sample(linearSampler, inFrag.uv);
    float4 out = uniforms.colorTransform * texColor * inFrag.color;
    out = linearRgbToNormalizedSrgb(out);
    return half4(out);
}


float4 linearRgbToNormalizedSrgb(float4 color) {
    float4 mask = step(0.0031308, color);
    float4 srgb = mask * pow(color * 1.055, 1/2.4) - 0.055 + (1-mask) * color * 12.92;
    return srgb;
}
