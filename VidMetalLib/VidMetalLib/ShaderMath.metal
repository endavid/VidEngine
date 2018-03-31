//
//  ShaderMath.metal
//  VidEngine
//
//  Created by David Gavilan on 9/3/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

#include <metal_stdlib>
#include "ShaderMath.h"
using namespace metal;

/// Quaternion Inverse
float4 quatInv(const float4 q) {
    // assume it's a unit quaternion, so just Conjugate
    return float4( -q.xyz, q.w );
}

/// Quaternion multiplication
float4 quatDot(const float4 q1, const float4 q2) {
    float scalar = q1.w * q2.w - dot(q1.xyz, q2.xyz);
    float3 v = cross(q1.xyz, q2.xyz) + q1.w * q2.xyz + q2.w * q1.xyz;
    return float4(v, scalar);
}

/// Apply unit quaternion to vector (rotate vector)
float3 quatMul(const float4 q, const float3 v) {
    float4 r = quatDot(q, quatDot(float4(v, 0), quatInv(q)));
    return r.xyz;
}

float4 linearRgbToNormalizedSrgb(float4 color) {
    float3 mask = step(0.0031308, abs(color.rgb));
    float3 srgb = mask * sign(color.rgb) * (pow(abs(color.rgb), 1/2.4) * 1.055 - 0.055) + (1-mask) * color.rgb * 12.92;
    return float4(srgb, color.a);
}

float4 normalizedSrgbToLinearRgb(float4 color) {
    float3 mask = step(0.04045, abs(color.rgb));
    float3 rgb = mask * sign(color.rgb) * powr((abs(color.rgb) + 0.055) / 1.055, 2.4) + (1-mask) * color.rgb / 12.92;
    return float4(rgb.rgb, color.a);
}

