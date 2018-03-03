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
    init?(device: MTLDevice, library: MTLLibrary, input: MTLTexture) {
        super.init()
        guard let vfn = library.makeFunction(name: "passThrough2DVertex"),
          let fragmentMin = library.makeFunction(name: "passFindMinimum")
        else {
            NSLog("Failed to create shaders")
            return nil
        }
        let pixelFormat = MTLPixelFormat.rgba16Unorm
        var w = input.width
        var h = input.height
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vfn
        pipelineDescriptor.fragmentFunction = fragmentMin
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        pipelineDescriptor.sampleCount = 1
        var inputTexture = input
        while w > 1 || h > 1 {
            w = max(1, w >> 1)
            h = max(1, h >> 1)
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: w, height: h, mipmapped: false)
            descriptor.usage = [.shaderRead, .renderTarget]
            guard let output = device.makeTexture(descriptor: descriptor) else {
                NSLog("Failed to create textures")
                return nil
            }
            guard let filter = TextureFilter(id: "Min\(w)x\(h)", device: device, descriptor: pipelineDescriptor) else {
                NSLog("Failed to create filters")
                return nil
            }
            // pixelSize of the input texture
            let pixelWidth = 1 / Float(2 * w)
            let pixelHeight = 1 / Float(2 * h)
            filter.inputs = [inputTexture]
            filter.output = output
            filter.buffer = Renderer.createSyncBuffer(from: float4(-pixelWidth, -pixelHeight, pixelWidth, pixelHeight), device: device)
            chain.append(filter)
            inputTexture = output
        }
    }
}
