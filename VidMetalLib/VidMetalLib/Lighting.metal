//
//  Lighting.metal
//  VidEngine
//
//  Created by David Gavilan on 9/3/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

#include <metal_stdlib>
#include "ShaderCommon.h"
#include "ShaderMath.h"
using namespace metal;

struct DirectionalLightInstance
{
    float4 color;
    float4 direction;
};

struct DirectionalLightVertexInOut {
    float4  position [[position]];
    float4  color;
    float4  direction;
    float2  uv;
};

float3x3 getViewRotation(float4x4 viewMatrix) {
    float3x3 viewRotation;
    viewRotation[0].xyz = viewMatrix[0].xyz;
    viewRotation[1].xyz = viewMatrix[1].xyz;
    viewRotation[2].xyz = viewMatrix[2].xyz;
    return viewRotation;
}

vertex VertexGBuffer passLightGeometry(uint vid [[ vertex_id ]],
  uint iid [[ instance_id ]],
  constant TexturedVertex* vdata [[ buffer(0) ]],
  constant Uniforms& uniforms  [[ buffer(1) ]],
  constant PerInstanceUniforms* perInstanceUniforms [[ buffer(2) ]])
{
    VertexGBuffer outVertex;
    Transform t = perInstanceUniforms[iid].transform;
    Material mat = perInstanceUniforms[iid].material;
    TexturedVertex v = vdata[vid];
    float3 worldNormal = normalize(quatMul(t.rotation, v.normal));
    float4 viewPos = uniforms.viewMatrix * float4(t * v.position, 1.0);
    float4 viewNormal = uniforms.viewMatrix * float4(worldNormal, 0.0);
    outVertex.position = uniforms.projectionMatrix * viewPos;
    outVertex.uv = float2(0,0);
    outVertex.color = mat.diffuse;
    outVertex.normal = viewNormal.xyz;
    return outVertex;
}

fragment FragmentGBuffer passLightFragment(
  VertexGBuffer inFrag [[stage_in]],
  texture2d<float> tex [[ texture(0) ]])
{
    FragmentGBuffer outFragment;
    float4 texColor = tex.sample(linearSampler, inFrag.uv);
    outFragment.albedo = half4(texColor * inFrag.color);
    outFragment.normal = float4(inFrag.normal, 1.0);
    return outFragment;
};


vertex DirectionalLightVertexInOut directionalLightVertex(
  uint vid [[ vertex_id ]],
  uint iid [[ instance_id ]],
  const device packed_float4* vdata [[ buffer(0) ]],
  constant Uniforms& uniforms  [[ buffer(1) ]],
  const device DirectionalLightInstance* instances [[ buffer(2) ]])
{
    DirectionalLightVertexInOut out;
    float4 xyuv = vdata[vid];
    out.position = float4(xyuv.xy, 0, 1);
    out.color = instances[iid].color;
    out.uv = xyuv.zw;
    // light direction in view space (normals are in view space as well)
    float3x3 viewRotation = getViewRotation(uniforms.viewMatrix);
    out.direction = float4(viewRotation * instances[iid].direction.xyz, 0.0);
    return out;
}

fragment half4 lightAccumulationDirectionalLight(
  DirectionalLightVertexInOut inFrag [[stage_in]],
  texture2d<float> normalTex [[ texture(0) ]])
{
    float4 normal = normalTex.sample(linearSampler, inFrag.uv);
    float3 direction = inFrag.direction.xyz;
    float4 out = inFrag.color;
    float cosTi = max(dot(normal.xyz, direction), 0.0);
    out.rgb *= cosTi;
    // specular
    // in view space, view direction is always the Z axis
    float3 viewDirection = float3(0,0,1);
    float3 h = normalize(viewDirection + direction);
    float cosH = max(dot(h, normal.xyz), 0.0);
    float m = 16.0;
    float spec = cosTi * pow(cosH, m) * (m + 8.0) / 8.0;
    float arbitraryScale = 0.1;
    out.a = arbitraryScale * spec;
    return half4(out);
};

fragment half4 passLightShading(
  VertexInOut inFrag [[stage_in]],
  texture2d<float> albedoTex [[ texture(0) ]],
  texture2d<float> lightTex [[ texture(1) ]])
{
    float4 albedo = albedoTex.sample(linearSampler, inFrag.uv);
    float4 light = lightTex.sample(linearSampler, inFrag.uv);
    float4 out = float4(albedo.rgb * light.rgb + light.a, albedo.a);
    return half4(out);
}
