//
//  Dots.metal
//  VidMetalLib
//
//  Created by David Gavilan on 2019/03/02.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

#include <metal_stdlib>
#include "ShaderCommon.h"
#include "ShaderMath.h"

using namespace metal;

struct DotVertex {
    float4  position [[position]];
    float4  color;
    float   size [[point_size]];
};

struct DotInstance {
    Transform transform;
    float4 dotSize;
};

vertex DotVertex dotsVertex(
  uint vid [[ vertex_id ]],
  uint iid [[ instance_id ]],
  constant packed_float3* vdata [[ buffer(0) ]],
  constant Uniforms& scene [[ buffer(1) ]],
  constant packed_float3* colors [[ buffer(2) ]],
  constant DotInstance* dotInstance [[ buffer(3) ]])
{
    DotVertex out;
    DotInstance instance = dotInstance[iid];
    Transform t = instance.transform;
    float3 v = vdata[vid];
    float3 c = colors[vid];
    float4 viewPos = scene.viewMatrix * float4(t * v, 1.0);
    out.position = scene.projectionMatrix * viewPos;
    out.color = float4(c, 1.0);
    out.size = instance.dotSize.x;
    return out;
}

fragment half4 dotsFragment(
  DotVertex inFrag [[ stage_in ]])
{
    return half4(inFrag.color);
}
