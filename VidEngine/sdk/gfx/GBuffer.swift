//
//  GBuffer.swift
//  VidEngine
//
//  Created by David Gavilan on 9/10/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit


struct GBuffer {
    let width : Int
    let height : Int
    let depthTexture : MTLTexture
    let albedoTexture : MTLTexture
    let normalTexture : MTLTexture
    let lightTexture : MTLTexture // light accumulation buffer
    
    init(device: MTLDevice, size: CGSize) {
        width = Int(size.width)
        height = Int(size.height)
        let depthDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: width, height: height, mipmapped: false)
        let albedoDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm_srgb, width: width, height: height, mipmapped: false)
        let normalDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Snorm, width: width, height: height, mipmapped: false)
        let lightDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Snorm, width: width, height: height, mipmapped: false)
        depthTexture = device.makeTexture(descriptor: depthDesc)
        depthTexture.label = "GBuffer:Depth"
        albedoTexture = device.makeTexture(descriptor: albedoDesc)
        albedoTexture.label = "GBuffer:Albedo"
        normalTexture = device.makeTexture(descriptor: normalDesc)
        normalTexture.label = "GBuffer:Normal"
        lightTexture = device.makeTexture(descriptor: lightDesc)
        lightTexture.label = "LightAccumulation"
    }
}
