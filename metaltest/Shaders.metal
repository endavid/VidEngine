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

struct LineParticle
{
    float4 start;
    float4 end;
};

struct Uniforms {
    float elapsedTime;
};

constexpr sampler pointSampler(coord::normalized, filter::nearest, address::repeat);


vertex VertexInOut passThroughVertex(uint vid [[ vertex_id ]],
                                     constant packed_float4* position  [[ buffer(0) ]],
                                     constant float* alpha    [[ buffer(1) ]])
{
    VertexInOut outVertex;
    
    outVertex.position = position[vid];
    outVertex.color    = float4(vid % 2,1,1, alpha[vid]);
    //outVertex.color    = float4(1,0,0,1);
    return outVertex;
};

// can only write to a buffer if the output is set to void
vertex void updateRaindrops(uint vid [[ vertex_id ]],
                            constant LineParticle* particle  [[ buffer(0) ]],
                            device LineParticle* updatedParticle  [[ buffer(1) ]],
                            constant Uniforms& uniforms  [[ buffer(2) ]],
                            texture2d<float> noiseTexture [[ texture(0) ]])
{
    LineParticle outParticle;
    float4 velocity = float4(0, -uniforms.elapsedTime, 0, 0);
    outParticle.start = particle[vid].start + velocity;
    outParticle.end = particle[vid].end + velocity;
    if (outParticle.start.y < -1) {
        // convert 1D position to UV coordinate
        int textureSize = 128;
        int pixel = int(outParticle.end.x * float(textureSize * textureSize));
        int u = pixel / textureSize;
        int v = pixel % textureSize;
        float2 uv = float2(float(u)/float(textureSize), float(v)/float(textureSize));
        float2 randomVec = noiseTexture.sample(pointSampler, uv).xy;
        outParticle.end.x = 2 * randomVec.x - 1;
        outParticle.end.y = 1 + 2 * randomVec.y;
        outParticle.start.x = outParticle.end.x;
        outParticle.start.y = outParticle.end.y + 0.1;
    }
    updatedParticle[vid] = outParticle;
};

fragment half4 passThroughFragment(VertexInOut inFrag [[stage_in]])
{
    return half4(inFrag.color);
};
