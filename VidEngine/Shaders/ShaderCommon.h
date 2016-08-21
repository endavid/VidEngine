//
//  Header.h
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

#pragma once
using namespace metal;

struct Uniforms {
    float elapsedTime;
    float windDirection;
    float2 touchPosition;
    float4x4 projectionMatrix;
    float4x4 viewMatrix;
};

struct PerInstanceUniforms
{
    float4x4 modelMatrix;
};