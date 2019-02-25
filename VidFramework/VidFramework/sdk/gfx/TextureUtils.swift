//
//  TextureUtils.swift
//  VidFramework
//
//  Created by David Gavilan on 2019/02/25.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import MetalKit

class TextureUtils {
    static func createWhiteTexture(device: MTLDevice) -> MTLTexture {
        let data : [UInt32] = [0xffffffff]
        let texDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 1, height: 1, mipmapped: false)
        let texture = device.makeTexture(descriptor: texDescriptor)
        let region = MTLRegionMake2D(0, 0, 1, 1)
        texture?.replace(region: region, mipmapLevel: 0, withBytes: data, bytesPerRow: 4 * 4)
        return texture!
    }
    static func createWhiteCubemap(device: MTLDevice) -> MTLTexture {
        let data : [UInt32] = [0xffffffff]
        let texDescriptor = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .rgba8Unorm, size: 1, mipmapped: false)
        let texture = device.makeTexture(descriptor: texDescriptor)!
        let region = MTLRegionMake3D(0, 0, 0, 1, 1, 1)
        texture.replace(region: region, mipmapLevel: 0, withBytes: data, bytesPerRow: 4 * 4)
        return texture
    }
}
