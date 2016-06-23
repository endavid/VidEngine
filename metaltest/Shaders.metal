//
//  Shaders.metal
//  metaltest
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

vertex VertexInOut passThroughVertex(uint vid [[ vertex_id ]],
                                     constant packed_float4* position  [[ buffer(0) ]],
                                     constant float* alpha    [[ buffer(1) ]])
{
    VertexInOut outVertex;
    
    outVertex.position = position[vid];
    outVertex.color    = float4(1,1,1, alpha[vid]);
    //outVertex.color    = float4(1,0,0,1);
    
    return outVertex;
};

fragment half4 passThroughFragment(VertexInOut inFrag [[stage_in]])
{
    return half4(inFrag.color);
};