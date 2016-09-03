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


vertex VertexInOut passLightGeometry(uint vid [[ vertex_id ]],
                                uint iid [[ instance_id ]],
                                constant TexturedVertex* vdata [[ buffer(0) ]],
                                constant Uniforms& uniforms  [[ buffer(1) ]],
                                constant Transform* perInstanceUniforms [[ buffer(2) ]])
{
    VertexInOut outVertex;
    Transform t = perInstanceUniforms[iid];
    float4x4 m = uniforms.projectionMatrix * uniforms.viewMatrix;
    TexturedVertex v = vdata[vid];
    float3 sunDirection = normalize(float3(1,1,-0.5));
    float3 worldNormal = normalize(quatMul(t.rotation, v.normal));
    float cosTi = dot(worldNormal, sunDirection);

    outVertex.position = m * float4(t * v.position, 1.0);
    outVertex.color = float4(cosTi, cosTi, cosTi, 1);
    return outVertex;
}

fragment half4 passLightFragment(VertexInOut inFrag [[stage_in]],
                                 texture2d<float> tex [[ texture(0) ]])
{
    float4 texColor = tex.sample(linearSampler, float2(0,0));
    return half4(texColor * inFrag.color);
};
