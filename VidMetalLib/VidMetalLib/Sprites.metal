//
//  Sprites.metal
//  VidEngine
//
//  Created by David Gavilan on 10/9/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

#include <metal_stdlib>
#include "ShaderCommon.h"
#include "ShaderMath.h"
using namespace metal;


vertex VertexInOut passSprite2DVertex(uint vid [[ vertex_id ]],
                                constant ColoredUnlitTexturedVertex* vdata [[ buffer(0) ]])
{
    VertexInOut outVertex;
    ColoredUnlitTexturedVertex v = vdata[vid];
    outVertex.position = float4(v.position, 1.0);
    outVertex.uv = v.texCoords;
    outVertex.color = float4(1,1,1,1); // v.color
    return outVertex;
}
