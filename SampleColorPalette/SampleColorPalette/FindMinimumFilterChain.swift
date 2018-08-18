//
//  FindMinimumFilterChain.swift
//  SampleColorPalette
//
//  Created by David Gavilan on 2018/03/03.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import VidFramework
import simd

class FindMinimumFilterChain: FilterChain {
    init?(device: MTLDevice, library: MTLLibrary, input: Texture) {
        super.init()
        guard let vfn = library.makeFunction(name: "passThrough2DVertex"),
          let fragmentMin = library.makeFunction(name: "passFindMinimum")
        else {
            NSLog("Failed to create shaders")
            return nil
        }
        guard let inputTexture = input.mtlTexture else {
            return nil
        }
        let pixelFormat = MTLPixelFormat.rgba16Unorm
        var w = inputTexture.width
        var h = inputTexture.height
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vfn
        pipelineDescriptor.fragmentFunction = fragmentMin
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        pipelineDescriptor.sampleCount = 1
        var input_i = input
        while w > 1 || h > 1 {
            w = max(1, w >> 1)
            h = max(1, h >> 1)
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: w, height: h, mipmapped: false)
            descriptor.usage = [.shaderRead, .renderTarget]
            guard let outputTexture = device.makeTexture(descriptor: descriptor) else {
                NSLog("Failed to create textures")
                return nil
            }
            guard let filter = TextureFilter(id: "Min\(w)x\(h)", device: device, descriptor: pipelineDescriptor) else {
                NSLog("Failed to create filters")
                return nil
            }
            let output = Texture(id: "Min\(w)x\(h)", mtlTexture: outputTexture)
            // pixelSize of the input texture = 1/(2*w)
            // because the texel is in the middle of the pixel, we move half the pixel size to one side and the other
            let texelU = 0.5 / Float(2 * w)
            let texelV = 0.5 / Float(2 * h)
            filter.inputs = [input_i]
            filter.output = output
            filter.fragmentBuffer = Renderer.createSyncBuffer(from: float4(-texelU, -texelV, texelU, texelV), device: device)
            chain.append(filter)
            input_i = output
        }
    }
}
