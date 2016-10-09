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

struct FragmentGBuffer {
    half4 albedo [[ color(0) ]];
    float4 normal [[ color(1) ]];
};

vertex VertexGBuffer passLightGeometry(uint vid [[ vertex_id ]],
                                uint iid [[ instance_id ]],
                                constant TexturedVertex* vdata [[ buffer(0) ]],
                                constant Uniforms& uniforms  [[ buffer(1) ]],
                                constant PerInstanceUniforms* perInstanceUniforms [[ buffer(2) ]])
{
    VertexGBuffer outVertex;
    Transform t = perInstanceUniforms[iid].transform;
    Material mat = perInstanceUniforms[iid].material;
    float4x4 m = uniforms.projectionMatrix * uniforms.viewMatrix;
    TexturedVertex v = vdata[vid];
    float3 worldNormal = normalize(quatMul(t.rotation, v.normal));
    outVertex.position = m * float4(t * v.position, 1.0);
    outVertex.uv = float2(0,0);
    outVertex.color = mat.diffuse;
    outVertex.normal = worldNormal;
    return outVertex;
}

fragment FragmentGBuffer passLightFragment(VertexGBuffer inFrag [[stage_in]],
                                 texture2d<float> tex [[ texture(0) ]])
{
    FragmentGBuffer outFragment;
    float4 texColor = tex.sample(linearSampler, inFrag.uv);
    outFragment.albedo = half4(texColor * inFrag.color);
    outFragment.normal = float4(inFrag.normal, 1.0);
    return outFragment;
};

fragment half4 passLightShading(VertexInOut inFrag [[stage_in]],
                                texture2d<float> albedoTex [[ texture(0) ]],
                                texture2d<float> normalTex [[ texture(1) ]])
{
    float4 albedo = albedoTex.sample(linearSampler, inFrag.uv);
    float4 normal = normalTex.sample(linearSampler, inFrag.uv);
    float3 sunDirection = normalize(float3(1,1,-0.5));
    float cosTi = dot(normal.xyz, sunDirection);
    float4 out = albedo * float4(cosTi, cosTi, cosTi, 1);
    return half4(out);
}
