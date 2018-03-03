//
//  MyFilters.swift
//  SampleColorPalette
//
//  Created by David Gavilan on 2018/03/03.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import VidFramework
import Metal
import simd

class MyFilters {
    var p3TosRgb: FilterChain
    var p3ToGammaP3: FilterChain
    var isCompleted: Bool {
        get {
            return p3ToGammaP3.isCompleted && p3TosRgb.isCompleted
        }
    }
    
    init?(device: MTLDevice, input: MTLTexture, colorTransform: float4x4) {
        guard let library = device.makeDefaultLibrary() else {
            NSLog("Failed to create default Metal library")
            return nil
        }
        guard let vfn = library.makeFunction(name: "passThrough2DVertex") else {
            NSLog("Failed to create vertex function")
            return nil
        }
        guard let ffn = library.makeFunction(name: "passColorTransformFragment") else {
            NSLog("Failed to create fragment function")
            return nil
        }
        let outputSRgb = Texture(device: device, id: "sRGB", width: input.width, height: input.height, data: [UInt32].init(repeating: 0, count: input.width * input.height), usage: [.renderTarget, .shaderRead])
        guard let mtlSrgb = outputSRgb.mtlTexture else {
            return nil
        }
        let outputP3 = Texture(device: device, id: "p3gamma", width: input.width, height: input.height, data: [UInt64].init(repeating: 0, count: input.width * input.height), usage: [.renderTarget, .shaderRead])
        guard let mtlP3 = outputP3.mtlTexture else {
            return nil
        }
        let descriptorSrgb = MTLRenderPipelineDescriptor()
        descriptorSrgb.vertexFunction = vfn
        descriptorSrgb.fragmentFunction = ffn
        descriptorSrgb.colorAttachments[0].pixelFormat = mtlSrgb.pixelFormat
        descriptorSrgb.sampleCount = mtlSrgb.sampleCount
        let descriptorP3 = MTLRenderPipelineDescriptor()
        descriptorP3.vertexFunction = vfn
        descriptorP3.fragmentFunction = ffn
        descriptorP3.colorAttachments[0].pixelFormat = mtlP3.pixelFormat
        descriptorP3.sampleCount = mtlP3.sampleCount
        guard let filterSrgb = TextureFilter(id: "toSrgb", device: device, descriptor: descriptorSrgb) else {
            NSLog("Failed to create TextureFilter")
            return nil
        }
        guard let filterP3 = TextureFilter(id: "toP3Gamma", device: device, descriptor: descriptorP3) else {
            NSLog("Failed to create TextureFilter")
            return nil
        }
        filterSrgb.input = input
        filterSrgb.output = mtlSrgb
        filterSrgb.buffer = MyFilters.bufferFromMatrix(device: device, m: colorTransform)
        filterP3.input = input
        filterP3.output = mtlP3
        filterP3.buffer = MyFilters.bufferFromMatrix(device: device, m: float4x4.identity)
        p3TosRgb = FilterChain()
        p3TosRgb.chain.append(filterSrgb)
        p3ToGammaP3 = FilterChain()
        p3ToGammaP3.chain.append(filterP3)
        p3TosRgb.queue()
        p3ToGammaP3.queue()
    }
    
    private static func bufferFromMatrix(device: MTLDevice, m: float4x4) -> MTLBuffer? {
        guard let buffer = device.makeBuffer(length: MemoryLayout<float4x4>.size, options: []) else {
            NSLog("Failed to create MTLBuffer")
            return nil
        }
        let vb = buffer.contents().assumingMemoryBound(to: float4x4.self)
        vb[0] = m
        return buffer
    }
}
