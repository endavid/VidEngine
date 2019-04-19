//
//  Interaction.metal
//  VidMetalLib
//
//  Created by David Gavilan on 2019/04/19.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

#include <metal_stdlib>
#import "ShaderCommon.h"
using namespace metal;

struct WorldTouchPoint {
    packed_float3 position;
    uint16_t      objectId;
    uint16_t      padding;
};

// can only write to a buffer if the output is set to void
vertex void getTouchedPoints(
  uint vid [[ vertex_id ]],
  constant packed_float2* uvs [[ buffer(0) ]],
  constant Scene& scene [[ buffer(1) ]],
  device WorldTouchPoint* points [[ buffer(2) ]],
  texture2d<uint16_t> objectTex [[ texture(0) ]],
  texture2d<float> depthTex [[texture(1)]])
{
    float2 uv = uvs[vid];
    WorldTouchPoint point;
    point.objectId = objectTex.sample(pointSampler, uv).r;
    float z = depthTex.sample(linearSampler, uv).r;
    // @todo compute world position from uv & z
    point.position = float3(z, z, z);
    points[vid] = point;
}
