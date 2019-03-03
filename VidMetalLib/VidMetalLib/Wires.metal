//
//  Wires.metal
//  VidMetalLib
//
//  Created by David Gavilan on 2019/03/03.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

#include <metal_stdlib>
#import "ShaderCommon.h"

using namespace metal;

struct WireVertex {
    float4  position [[position]];
    float4  color;
};

struct WireInstance {
    Transform transform;
    float4 color;
};

vertex WireVertex wiresVertex(
  uint vid [[ vertex_id ]],
  uint iid [[ instance_id ]],
  constant packed_float4* vdata [[ buffer(0) ]],
  constant Scene& scene [[ buffer(1) ]],
  constant WireInstance* instances [[ buffer(2) ]])
{
    WireVertex out;
    WireInstance instance = instances[iid];
    Transform t = instance.transform;
    float4 v = vdata[vid];
    float4 viewPos = scene.viewMatrix * float4(t * v.xyz, 1.0);
    out.position = scene.projectionMatrix * viewPos;
    out.color = instance.color;
    return out;
}

fragment half4 wiresFragment(
  WireVertex inFrag [[ stage_in ]])
{
    return half4(inFrag.color);
}
