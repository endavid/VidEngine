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
