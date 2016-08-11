//
//  Shaders.metal
//
//  Created by David Gavilan on 3/31/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

#include <metal_stdlib>
#include "ShaderMath.h"

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
    Quat q;
    q.SetW(4);
    
    float4 posAndVelocity = position[vid];
    outVertex.position = float4(posAndVelocity.xy, 0, 1);
    outVertex.color    = float4(vid % 2,q.GetW(),1, 0.1 + 0.5 * (vid % 2));
    return outVertex;
};

vertex VertexInOut passGeometry(uint vid [[ vertex_id ]],
                                constant packed_float4* position [[ buffer(0) ]])
{
    VertexInOut outVertex;
    float4x4 m = float4x4(float4(2.4,0.03,0.02,0.02), // 1st column
                  float4(-0.04,1.6,-0.02,-0.02), // 2nd col
                  float4(0.05,-0.03,-1,-1),
                  float4(0, 0, 19.8, 20));
    float4 pos = position[vid];
    outVertex.position = m * float4(pos.xyz, 1.0);
    outVertex.color = float4(1, 1, 1, 1);
    return outVertex;
}

fragment half4 passThroughFragment(VertexInOut inFrag [[stage_in]])
{
    return half4(inFrag.color);
};
