//
//  Harmonics.metal
//  VidMetalLib
//
//  Created by David Gavilan on 2019/02/23.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

#include <metal_stdlib>
#include "ShaderCommon.h"
#include "ShaderMath.h"

using namespace metal;

struct SHLightVertexInOut {
    float4 position [[position]];
    float4 pos;
    float4 tonemap;
};

struct SHInstance {
    Transform transform;
    float4 tonemap;
};

// can only write to a buffer if the output is set to void
vertex void readCubemapSamples(
  uint vid [[ vertex_id ]],
  constant packed_float3* normals [[ buffer(0) ]],
  device packed_float3* radiances [[ buffer(1) ]],
  texturecube<float> tex [[ texture(0) ]]
)
{
    float3 n = normals[vid];
    float4 c = tex.sample(cubemapSampler, n);
    // cubemap texture format MTLPixelFormatBGRA8Unorm_sRGB
    // so no need to manually convert to linear
    radiances[vid] = c.rgb;
}

vertex SHLightVertexInOut shLightVertex(
  uint vid [[ vertex_id ]],
  uint iid [[ instance_id ]],
  constant TexturedVertex* vdata [[ buffer(0) ]],
  constant Uniforms& uniforms [[ buffer(1) ]],
  constant SHInstance& instance [[ buffer(2) ]])
{
    SHLightVertexInOut out;
    TexturedVertex v = vdata[vid];
    Transform t = instance.transform;
    float4 viewPos = uniforms.viewMatrix * float4(t * v.position, 1.0);
    float4 p = uniforms.projectionMatrix * viewPos;
    out.position = p;
    out.pos = p;
    out.tonemap = instance.tonemap;
    return out;
}

fragment half4 lightAccumulationSHLight(
  SHLightVertexInOut inFrag [[stage_in]],
  constant float4x4* irradiances [[ buffer(0) ]],
  texture2d<float> normalTex [[ texture(0) ]])
{
    // @see getIrradianceApproximation
    // Computes the approximate irradiance for the given normal direction
    // E(n) = n^ * M * n
    float2 uv = 0.5 * inFrag.pos.xy / inFrag.pos.w;
    uv = float2(uv.x + 0.5, 0.5 - uv.y);
    float4 normal = normalTex.sample(linearSampler, uv);
    float4 n = float4(-normal.zx, normal.y, 1);
    float x = dot(n, irradiances[0] * n);
    float y = dot(n, irradiances[1] * n);
    float z = dot(n, irradiances[2] * n);
    float specular = 0;
    float4 out = float4(x, y, z, specular) * inFrag.tonemap;
    return half4(out);
    //return half4(inFrag.uv.x, inFrag.uv.y, 0, 1);
    //return half4(half3(normal.xyz), 1.0);
};
