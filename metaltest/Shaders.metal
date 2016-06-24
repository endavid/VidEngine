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

float2 uvForNoiseTexture(float clipx);

vertex VertexInOut passThroughVertex(uint vid [[ vertex_id ]],
                                     constant packed_float4* position  [[ buffer(0) ]],
                                     constant float* alpha    [[ buffer(1) ]])
{
    VertexInOut outVertex;
    
    float4 posAndVelocity = position[vid];
    outVertex.position = float4(posAndVelocity.xy, 0, 1);
    outVertex.color    = float4(vid % 2,1,1, alpha[vid]);
    //outVertex.color    = float4(1,0,0,1);
    return outVertex;
};

// convert 1D position to UV coordinate
float2 uvForNoiseTexture(float clipx) {
    float x = 0.5 * clipx + 0.5;
    int textureSize = 128;
    int pixel = int(x * float(textureSize * textureSize));
    int u = pixel / textureSize;
    int v = pixel % textureSize;
    float2 uv = float2(float(u)/float(textureSize), float(v)/float(textureSize));
    return uv;
}

// can only write to a buffer if the output is set to void
vertex void updateRaindrops(uint vid [[ vertex_id ]],
                            constant LineParticle* particle  [[ buffer(0) ]],
                            device LineParticle* updatedParticle  [[ buffer(1) ]],
                            constant Uniforms& uniforms  [[ buffer(2) ]],
                            texture2d<float> noiseTexture [[ texture(0) ]])
{
    LineParticle outParticle;
    float4 velocity = uniforms.elapsedTime * float4(particle[vid].start.zw, particle[vid].end.zw);
    outParticle.start = particle[vid].start + float4(velocity.xy, 0, 0);
    outParticle.end = particle[vid].end + float4(velocity.zw, 0, 0);
    if (outParticle.end.y < -1 && velocity.w < 0) { // hit the ground (or obstacle)
        outParticle.end.zw = float2(0,0);
    }
    else if (outParticle.start.y < -1 && velocity.y < 0) { // hit the ground (or obstacle)
        float2 uv = uvForNoiseTexture(outParticle.end.x);
        float2 randomVec = noiseTexture.sample(pointSampler, uv).xy;
        randomVec.x = 2 * randomVec.x - 1;
        randomVec.x = randomVec.x < 0 ? 0.1 * randomVec.x - 0.001 : 0.1 * randomVec.x + 0.001;
        randomVec.y = 0.1 + 0.2 * randomVec.y;
        outParticle.end.zw = randomVec;
        outParticle.start.zw = float2(0,0);
    }
    else if (outParticle.end.y - outParticle.start.y > 0.05) { // reset particle after bounce
        float2 uv = uvForNoiseTexture(outParticle.end.x);
        float2 randomVec = noiseTexture.sample(pointSampler, uv).xy;
        float2 randomVelocity = noiseTexture.sample(pointSampler, randomVec).xy;
        outParticle.end.x = 2 * randomVec.x - 1;
        outParticle.end.y = 1 + 2.4 * randomVec.y;
        outParticle.end.zw = float2(0,-0.9 - 0.2 * randomVelocity.y);
        outParticle.start.x = outParticle.end.x;
        outParticle.start.y = outParticle.end.y + 0.1;
        outParticle.start.zw = outParticle.end.zw;
    }
    updatedParticle[vid] = outParticle;
};

fragment half4 passThroughFragment(VertexInOut inFrag [[stage_in]])
{
    return half4(inFrag.color);
};
