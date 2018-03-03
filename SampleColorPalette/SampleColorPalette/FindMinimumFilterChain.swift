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
          let fragmentMin = library.makeFunction(name: "passFindMinimum"),
          let fragmentDistance = library.makeFunction(name: "passComputeDistance")
        else {
            NSLog("Failed to create shaders")
            return nil
        }
        let pixelFormat = MTLPixelFormat.rgba16Unorm
        let distTexDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: input.width, height: input.height, mipmapped: false)
        distTexDescriptor.usage = [.shaderRead, .renderTarget]
        guard let distOutput = device.makeTexture(descriptor: distTexDescriptor) else {
            NSLog("Failed to create texture")
            return nil
        }
        let distDescriptor = MTLRenderPipelineDescriptor()
        distDescriptor.vertexFunction = vfn
        distDescriptor.fragmentFunction = fragmentDistance
        distDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        distDescriptor.sampleCount = 1
        guard let filterDist = TextureFilter(id: "ComputeDistance", device: device, descriptor: distDescriptor) else {
            NSLog("Failed to create filter")
            return nil
        }
        filterDist.input = input
        filterDist.output = distOutput
        filterDist.buffer = Renderer.createBuffer(from: float4(0.5, 0.5, 0.5, 1.0), device: device)
        chain.append(filterDist)
        var w = max(1, input.width)
        var h = max(1, input.height)
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vfn
        pipelineDescriptor.fragmentFunction = fragmentMin
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        pipelineDescriptor.sampleCount = 1
        var inputTexture = distOutput
        /*
        while w > 1 || h > 1 {
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
            filter.input = inputTexture
            filter.output = output
            chain.append(filter)
            inputTexture = output
            w = max(1, w >> 1)
            h = max(1, h >> 1)
        }*/
    }
}
