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
    
    init(device: MTLDevice, size: CGSize) {
        width = Int(size.width)
        height = Int(size.height)
        let depthDesc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.Depth32Float, width: width, height: height, mipmapped: false)
        let albedoDesc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.RGBA8Unorm_sRGB, width: width, height: height, mipmapped: false)
        let normalDesc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.RGBA16Snorm, width: width, height: height, mipmapped: false)
        depthTexture = device.newTextureWithDescriptor(depthDesc)
        depthTexture.label = "GBuffer:Depth"
        albedoTexture = device.newTextureWithDescriptor(albedoDesc)
        albedoTexture.label = "GBuffer:Albedo"
        normalTexture = device.newTextureWithDescriptor(normalDesc)
        normalTexture.label = "GBuffer:Normal"
    }
}