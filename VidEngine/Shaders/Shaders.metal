//
//  Shaders.metal
//
//  Created by David Gavilan on 3/31/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

struct VertexInOut
{
    float4  position [[position]];
    float4  color;
};

vertex VertexInOut passVertexRaindrop(uint vid [[ vertex_id ]],
                                      constant packed_float4* position  [[ buffer(0) ]])
{
    VertexInOut outVertex;
    float4 posAndVelocity = position[vid];
    outVertex.position = float4(posAndVelocity.xy, 0, 1);
    outVertex.color    = float4(vid % 2,1,1, 0.1 + 0.5 * (vid % 2));
    return outVertex;
};

fragment half4 passThroughFragment(VertexInOut inFrag [[stage_in]])
{
    return half4(inFrag.color);
};
