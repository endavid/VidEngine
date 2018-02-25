//
//  TextureInit.swift
//  VidFramework
//
//  Created by David Gavilan on 2018/02/25.
//  Copyright © 2018 David Gavilan. All rights reserved.
//
//  Texture initializers

import MetalKit

public extension Texture {
    public init(device: MTLDevice, id: String, width: Int, height: Int, data: [UInt64]) {
        self.id = id
        let texDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Unorm, width: width, height: height, mipmapped: false)
        if let texture = device.makeTexture(descriptor: texDescriptor) {
            let region = MTLRegionMake2D(0, 0, width, height)
            texture.replace(region: region, mipmapLevel: 0, withBytes: data, bytesPerRow: 8 * width)
            mtlTexture = texture
        } else {
            mtlTexture = nil
        }
    }
}
