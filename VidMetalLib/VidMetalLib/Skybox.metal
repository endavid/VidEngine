//
//  Skybox.metal
//  VidMetalLib
//
//  Created by David Gavilan on 2019/02/24.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

#include <metal_stdlib>
#import "ShaderCommon.h"

using namespace metal;

struct VertexSkybox {
    float4  position [[position]];
    float3  normal;
};

vertex VertexSkybox passSkyboxGeometry(
  uint vid [[ vertex_id ]],
  uint iid [[ instance_id ]],
  constant TexturedVertex* vdata [[ buffer(0) ]],
  constant Scene& scene [[ buffer(1) ]],
  constant Transform* instances [[ buffer(2) ]])
{
    VertexSkybox outVertex;
    Transform t = instances[iid];
    TexturedVertex v = vdata[vid];
    float4 viewPos = scene.viewMatrix * float4(t * v.position, 1.0);
    outVertex.position = scene.projectionMatrix * viewPos;
    outVertex.normal = quatMul(t.rotation, v.normal);
    return outVertex;
}

fragment half4 passSkyboxFragment(
  VertexSkybox inFrag [[stage_in]],
  texturecube<float> tex [[ texture(0) ]],
  sampler sam [[ sampler(0) ]])
{
    float3 n = inFrag.normal;
    float4 out = float4(tex.sample(sam, n).rgb, 1.0);
    return half4(out);
}
