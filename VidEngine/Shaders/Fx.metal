//
//  Fx.metal
//  VidEngine
//
//  Created by David Gavilan on 7/31/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


struct LineParticle
{
    float4 start;
    float4 end;
};

struct Uniforms {
    float elapsedTime;
    float windDirection;
    float2 touchPosition;
};

constexpr sampler pointSampler(coord::normalized, filter::nearest, address::repeat);

float2 uvForNoiseTexture(float clipx);

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
    float4 velocity = float4(particle[vid].start.zw, particle[vid].end.zw);
    float speed = 1.5;
    velocity += uniforms.windDirection * float4(1, 0, 1, 0);
    velocity *= uniforms.elapsedTime * speed;
    outParticle.start = particle[vid].start + float4(velocity.xy, 0, 0);
    outParticle.end = particle[vid].end + float4(velocity.zw, 0, 0);
    float fingerWidth = 0.2;
    float dropHeight = 0.2;
    bool endHitFinger = outParticle.end.x > -0.5 * fingerWidth + uniforms.touchPosition.x && outParticle.end.x < 0.5 * fingerWidth + uniforms.touchPosition.x && outParticle.end.y < uniforms.touchPosition.y;
    bool startHitFinger = outParticle.start.x > -0.5 * fingerWidth + uniforms.touchPosition.x && outParticle.start.x < 0.5 * fingerWidth + uniforms.touchPosition.x && outParticle.start.y < uniforms.touchPosition.y;
    if ((outParticle.end.y < -1 || endHitFinger)  && velocity.w < 0) { // hit the ground (or obstacle)
        outParticle.end.zw = float2(0,0);
    }
    else if ((outParticle.start.y < -1 || startHitFinger) && velocity.y < 0) { // hit the ground (or obstacle)
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
        outParticle.end.y = 1 + 2.4 * randomVec.y;
        outParticle.end.zw = float2(0,-2 * (0.9 + 0.2 * randomVelocity.y));
        outParticle.start.x = 2 * randomVec.x - 1 - uniforms.windDirection; // apply wind offset to fill the screen
        outParticle.end.x = outParticle.start.x + 0.1 * uniforms.windDirection;
        outParticle.start.y = outParticle.end.y + dropHeight;
        outParticle.start.zw = outParticle.end.zw;
    }
    updatedParticle[vid] = outParticle;
};