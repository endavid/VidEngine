//
//  Transparency.metal
//  VidEngine
//
//  Created by David Gavilan on 2017/05/29.
//  Copyright © 2017 David Gavilan. All rights reserved.
//

#include <metal_stdlib>
#import "ShaderCommon.h"
using namespace metal;

vertex VertexOIT passGeometryOIT(
  uint vid [[ vertex_id ]],
  uint iid [[ instance_id ]],
  constant TexturedVertex* vdata [[ buffer(0) ]],
  constant Scene& scene [[ buffer(1) ]],
  constant PrimitiveInstance* instances [[ buffer(2) ]])
{
    VertexOIT outVertex;
    Transform t = instances[iid].transform;
    Material mat = instances[iid].material;
    TexturedVertex v = vdata[vid];
    float4 viewPos = scene.viewMatrix * float4(t * v.position, 1.0);
    outVertex.position = scene.projectionMatrix * viewPos;
    outVertex.uv = v.texCoords;// * mat.uvScale + mat.uvOffset;
    outVertex.color = mat.diffuse;
    //outVertex.color = float4(outVertex.uv, 0, 1);
    // distance from camera
    float w = (scene.nearTransparency.z - outVertex.position.z) * scene.nearTransparency.w;
    outVertex.weight = w;
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
    
    float smallestHalf = exp2(-14.0);
    float w = exp10(inFrag.weight);
    float weight = max(255.0 * smallestHalf, color.a * w);
    
    // Blend Func .add: .one, .one
    out.accumulation = color.rgba * weight;
    // Blend Func .add: .oneMinusSourceColor, .oneMinusSourceAlpha
    out.reveal = color.a;
    return out;
}

fragment half4 blendWithOIT(
  VertexInOut inFrag [[stage_in]],
  texture2d<float> tex [[ texture(0) ]],
  texture2d<float> accumulationTex [[ texture(1) ]],
  texture2d<float> revealTex [[ texture(2) ]])
{
    float4 texColor = tex.sample(linearSampler, inFrag.uv);
    float4 color = texColor * inFrag.color;
    float4 accum = accumulationTex.sample(linearSampler, inFrag.uv);
    float reveal = revealTex.sample(linearSampler, inFrag.uv).r;
    float4 oit = float4(accum.rgb / max(accum.a, 1e-24), reveal);
    color.rgb = color.rgb * oit.a + (1.0 - oit.a) * oit.rgb;
    color.a = (1.0 - oit.a) + oit.a * color.a;
    return half4(color);
}
