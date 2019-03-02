//
//  Header.h
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

#pragma once
#import "ShaderMath.h"
using namespace metal;

struct VertexInOut {
    float4  position [[position]];
    float4  color;
    float2  uv;
};

struct VertexGBuffer {
    float4  position [[position]];
    float4  color;
    float3  normal;
    float2  uv;
};

struct VertexOIT {
    float4  position [[position]];
    float4  color;
    float2  uv;
    float   weight;
};

struct FragmentGBuffer {
    half4 albedo [[ color(0) ]];
    float4 normal [[ color(1) ]];
};

struct FragmentOIT {
    float4 accumulation [[ color(0) ]];
    float reveal [[ color(1) ]];
};

struct TexturedVertex
{
    packed_float3 position;
    packed_float3 normal;
    packed_float2 texCoords;
};

struct ColoredUnlitTexturedVertex
{
    packed_float3 position;
    packed_float2 texCoords;
    packed_float4 color;
};

struct Scene {
    float elapsedTime;
    float windDirection;
    float2 touchPosition;
    float4x4 projectionMatrix;
    float4x4 viewMatrix;
};

struct Material {
    float4 diffuse;
};

struct PrimitiveInstance
{
    Transform transform;
    Material material;
};

constexpr sampler pointSampler(
    coord::normalized,
    filter::nearest,
    address::clamp_to_edge);
constexpr sampler linearSampler(
    coord::normalized,
    filter::linear,
    address::clamp_to_edge);
constexpr sampler cubemapSampler(
    coord::normalized,
    filter::linear,
    address::clamp_to_edge,
    mip_filter::linear);

float4 linearRgbToNormalizedSrgb(float4 color);
float4 normalizedSrgbToLinearRgb(float4 color);
