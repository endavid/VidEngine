//
//  TextRendering.metal
//  VidEngine
//
//  Created by David Gavilan on 2017/05/29.
//  Copyright © 2017 David Gavilan. All rights reserved.
//

#include <metal_stdlib>
#import "ShaderCommon.h"
using namespace metal;

constexpr sampler textSampler(coord::normalized, filter::linear, address::repeat);

fragment FragmentOIT passTextFragmentOIT(VertexOIT inFrag [[stage_in]],
                                         texture2d<float> tex [[ texture(0) ]])
{
    FragmentOIT out;
    float4 color = inFrag.color;
    // Outline of glyph is the isocontour with value 50%
    float edgeDistance = 0.5;
    // Sample the signed-distance field to find distance from this fragment to the glyph outline
    float sampleDistance = tex.sample(textSampler, inFrag.uv).r;
    // Use local automatic gradients to find anti-aliased anisotropic edge width, cf. Gustavson 2012
    float edgeWidth = 0.75 * length(float2(dfdx(sampleDistance), dfdy(sampleDistance)));
    // Smooth the glyph edge by interpolating across the boundary in a band with the width determined above
    float insideness = smoothstep(edgeDistance - edgeWidth, edgeDistance + edgeWidth, sampleDistance);
    color.a *= insideness;
    // The values computed below are for the OIT buffer
    color.rgb *= color.a;
    // Blend Func: GL_ONE, GL_ONE
    out.accumulation = float4(color.rgb * inFrag.weight, color.a);
    // Blend Func: GL_ZERO, GL_ONE_MINUS_SRC_ALPHA
    out.reveal = color.a * inFrag.weight;
    return out;
}

