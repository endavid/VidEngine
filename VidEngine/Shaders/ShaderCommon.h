//
//  Header.h
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

#pragma once
#include "ShaderMath.h"
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

struct Uniforms {
    float elapsedTime;
    float windDirection;
    float2 touchPosition;
    float4x4 projectionMatrix;
    float4x4 viewMatrix;
};

struct Material {
    float4 diffuse;
};

struct PerInstanceUniforms
{
    Transform transform;
    Material material;
};

constexpr sampler pointSampler(coord::normalized, filter::nearest, address::repeat);
constexpr sampler linearSampler(coord::normalized, filter::linear, address::repeat);
