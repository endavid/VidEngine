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
    float2 dummy;
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

fragment half4 passThroughFragment(
  VertexInOut inFrag [[stage_in]],
  texture2d<float> tex [[ texture(0) ]])
{
    float4 out = tex.sample(linearSampler, inFrag.uv);
    return half4(out);
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
    float4 texColor = tex.sample(pointSampler, inFrag.uv);
    float d = distance(texColor.rgb, color.v0.rgb);
    // store the UVs and the distance.
    // notice that the UVs are texel coordinates, so for the top-left pixel,
    // uv(0) = (0.5/pixelWidth, 0.5/pixelHeight)
    float4 out = float4(inFrag.uv, d, 1.0);
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
    if (a.z < b.z) {
        if (a.z < c.z) {
            return (a.z < d.z) ? a : d;
        }
        return (c.z < d.z) ? c : d;
    }
    if (b.z < c.z) {
        return (b.z < d.z) ? b : d;
    }
    return (c.z < d.z) ? c : d;
}

fragment half4 passSelfOrganizingMap(
     VertexInOut inFrag [[stage_in]],
     texture2d<float> tex [[ texture(0) ]],
     texture2d<float> minTex [[ texture(1) ]],
     constant SomData& somData [[ buffer(0) ]])
{
    float2 bmu = minTex.sample(pointSampler, float2(0.5, 0.5)).xy;
    float4 out = somUpdateNeuron(tex, inFrag.uv, somData.learningRate, somData.neighborhoodRadius, bmu, somData.target);
    return half4(out);
}

float4 linearRgbToNormalizedSrgb(float4 color) {
    float4 mask = step(0.0031308, color);
    float4 srgb = mask * pow(color, 1/2.4) * 1.055 - 0.055 + (1-mask) * color * 12.92;
    return srgb;
}

float4 somWeightUpdate(texture2d<float> tex, float2 uv, float delta, float4 targetColor) {
    float4 color = tex.sample(pointSampler, uv);
    return color + delta * (targetColor - color);
}

float4 somUpdateNeuron(texture2d<float> tex, float2 uv, float learningRate, float neighborhoodRadius, float2 bmu, float4 target) {
    float dd = distance_squared(bmu, uv);
    float rr = neighborhoodRadius * neighborhoodRadius;
    float influence = (dd < rr) ? exp(-dd / (2.0*rr)) : 0;
    //return (dd < rr) ? target : tex.sample(pointSampler, uv);
    return somWeightUpdate(tex, uv, learningRate * influence, target);
}
