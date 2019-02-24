//
//  Harmonics.metal
//  VidMetalLib
//
//  Created by David Gavilan on 2019/02/23.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

#include <metal_stdlib>
#include "ShaderCommon.h"

using namespace metal;

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
