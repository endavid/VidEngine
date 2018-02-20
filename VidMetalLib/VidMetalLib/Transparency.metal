//
//  Transparency.metal
//  VidEngine
//
//  Created by David Gavilan on 2017/05/29.
//  Copyright © 2017 David Gavilan. All rights reserved.
//

#include <metal_stdlib>
#include "ShaderCommon.h"
#include "ShaderMath.h"
using namespace metal;

vertex VertexOIT passGeometryOIT(uint vid [[ vertex_id ]],
                                 uint iid [[ instance_id ]],
                                 constant TexturedVertex* vdata [[ buffer(0) ]],
                                 constant Uniforms& uniforms  [[ buffer(1) ]],
                                 constant PerInstanceUniforms* perInstanceUniforms [[ buffer(2) ]])
{
    VertexOIT outVertex;
    Transform t = perInstanceUniforms[iid].transform;
    Material mat = perInstanceUniforms[iid].material;
    float4x4 m = uniforms.projectionMatrix * uniforms.viewMatrix;
    TexturedVertex v = vdata[vid];
    outVertex.position = m * float4(t * v.position, 1.0);
    outVertex.uv = v.texCoords;// * mat.uvScale + mat.uvOffset;
    outVertex.color = mat.diffuse;
    //outVertex.color = float4(outVertex.uv, 0, 1);
    // distance from camera
    float w = outVertex.position.z / outVertex.position.w;
    outVertex.weight = 100.0 * exp(-0.001 * w * w);
    return outVertex;
}

fragment FragmentOIT passFragmentOIT(VertexOIT inFrag [[stage_in]],
                                     texture2d<float> tex [[ texture(0) ]])
{
    FragmentOIT out;
    float4 texColor = tex.sample(linearSampler, inFrag.uv);
    float4 color = texColor * inFrag.color;

    // scaled view depth
    //float zScene = texture(texDepth, vfScreenCoord.xy).z;
    //float zFx = gl_FragCoord.z / gl_FragCoord.w;
    //zFx = zFx * vColorScale.x + vColorOffset.x;
    // soft particle
    //float fade = clamp(zScene - zFx, 0.0, 1.0);
    //color.a *= fade;
    // if texture has no premultiplied alpha, apply this,
    color.rgb *= color.a;

    // Blend Func: GL_ONE, GL_ONE
    out.accumulation = float4(color.rgb * inFrag.weight, color.a);
    // Blend Func: GL_ZERO, GL_ONE_MINUS_SRC_ALPHA
    out.reveal = color.a * inFrag.weight;
    return out;
}

fragment half4 passResolveOIT(VertexInOut inFrag [[stage_in]],
                              texture2d<float> accumulationTex [[ texture(0) ]],
                              texture2d<float> revealTex [[ texture(1) ]])
{
    float4 accum = accumulationTex.sample(linearSampler, inFrag.uv);
    float reveal = revealTex.sample(linearSampler, inFrag.uv).r;
    float r = accum.a;
    accum.a = reveal;
    // Blend Func: GL_ONE_MINUS_SRC_ALPHA, GL_SRC_ALPHA
    float4 out = float4(accum.rgb / clamp(accum.a, 1e-4, 5e4), r);
    return half4(out);
}

