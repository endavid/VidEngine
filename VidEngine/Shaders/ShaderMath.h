//
//  ShaderMath.h
//  VidEngine
//
//  Created by David Gavilan on 8/3/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

#pragma once

using namespace metal;

float4 quatInv(const float4 q);
float4 quatDot(const float4 q1, const float4 q2);
float3 quatMul(const float4 q, const float3 v);

struct Transform {
    float4 position;    // only xyz actually used
    float4 scale;       // only xyz actually used
    float4 rotation;    // unit quaternion; w is the scalar
    
    float3 operator* (const float3 v) const {
        return position.xyz + quatMul(rotation, v * scale.xyz);
    }
};

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