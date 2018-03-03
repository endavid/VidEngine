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
constexpr sampler pointSampler(coord::normalized, filter::nearest, address::clamp_to_edge);

struct VertexInOut {
    float4  position [[position]];
    float4  color;
    float2  uv;
};

struct Uniforms {
    float4x4 colorTransform;
};

struct FilterData {
    float4 v0;
};

struct SomData {
    float learningRate;
    float neighborhoodRadius;
    float2 bmu;
    float4 target;
};

float4 linearRgbToNormalizedSrgb(float4 color);
float4 somWeightUpdate(texture2d<float> tex, float2 uv, float delta, float4 targetColor);
float4 somUpdateNeuron(texture2d<float> tex, float2 uv, float learningRate, float neighborhoodRadius, float2 bmu, float4 target);

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

fragment half4 passComputeDistance(
    VertexInOut inFrag [[stage_in]],
    texture2d<float> tex [[ texture(0) ]],
    constant FilterData& color [[ buffer(0) ]])
{
    float4 texColor = tex.sample(linearSampler, inFrag.uv);
    float d = distance(texColor, color.v0);
    float4 out = float4(d, inFrag.uv, 1.0);
    return half4(out);
}

fragment half4 passFindMinimum(
    VertexInOut inFrag [[stage_in]],
    texture2d<float> tex [[ texture(0) ]],
    constant FilterData& pixelSize [[ buffer(0) ]])
{
    // store -dx, -dy, +dx, +dy in pixelSize
    float4 delta = pixelSize.v0;
    half4 a = half4(tex.sample(pointSampler, inFrag.uv + delta.xy));
    half4 b = half4(tex.sample(pointSampler, inFrag.uv + delta.zy));
    half4 c = half4(tex.sample(pointSampler, inFrag.uv + delta.xw));
    half4 d = half4(tex.sample(pointSampler, inFrag.uv + delta.zw));
    if (a.x < b.x) {
        if (a.x < c.x) {
            return (a.x < d.x) ? a : d;
        }
        return (c.x < d.x) ? c : d;
    }
    if (b.x < c.x) {
        return (b.x < d.x) ? b : d;
    }
    return (c.x < d.x) ? c : d;
}

fragment half4 passSelfOrganizingMap(
     VertexInOut inFrag [[stage_in]],
     texture2d<float> tex [[ texture(0) ]],
     constant SomData& somData [[ buffer(0) ]])
{
    float4 out = somUpdateNeuron(tex, inFrag.uv, somData.learningRate, somData.neighborhoodRadius, somData.bmu, somData.target);
    return half4(out);
}

float4 linearRgbToNormalizedSrgb(float4 color) {
    float4 mask = step(0.0031308, color);
    float4 srgb = mask * pow(color * 1.055, 1/2.4) - 0.055 + (1-mask) * color * 12.92;
    return srgb;
}

float4 somWeightUpdate(texture2d<float> tex, float2 uv, float delta, float4 targetColor) {
    float4 color = tex.sample(pointSampler, uv);
    return color + delta * (targetColor - color);
}

float4 somUpdateNeuron(texture2d<float> tex, float2 uv, float learningRate, float neighborhoodRadius, float2 bmu, float4 target) {
    float dd = distance_squared(bmu, uv);
    float rr = neighborhoodRadius * neighborhoodRadius;
    if (dd < rr) {
        float influence = exp(-dd / (2.0*rr));
        return somWeightUpdate(tex, uv, learningRate * influence, target);
    }
    return target;
}
