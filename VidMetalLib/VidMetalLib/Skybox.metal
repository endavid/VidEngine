//
//  Skybox.metal
//  VidMetalLib
//
//  Created by David Gavilan on 2019/02/24.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

#include <metal_stdlib>
#include "ShaderCommon.h"
#include "ShaderMath.h"

using namespace metal;

struct VertexSkybox {
    float4  position [[position]];
    float3  normal;
};

vertex VertexSkybox passSkyboxGeometry(
  uint vid [[ vertex_id ]],
  uint iid [[ instance_id ]],
  constant TexturedVertex* vdata [[ buffer(0) ]],
  constant Uniforms& uniforms  [[ buffer(1) ]],
  constant Transform* perInstanceUniforms [[ buffer(2) ]])
{
    VertexSkybox outVertex;
    Transform t = perInstanceUniforms[iid];
    TexturedVertex v = vdata[vid];
    float4 viewPos = uniforms.viewMatrix * float4(t * v.position, 1.0);
    outVertex.position = uniforms.projectionMatrix * viewPos;
    outVertex.normal = quatMul(t.rotation, v.normal);
    return outVertex;
}

fragment half4 passSkyboxFragment(
  VertexSkybox inFrag [[stage_in]],
  texturecube<float> tex [[ texture(0) ]])
{
    float3 n = inFrag.normal;
    float4 out = tex.sample(cubemapSampler, n);
    return half4(out);
}
