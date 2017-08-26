//
//  Image.swift
//
//  Created by David Gavilan on 6/23/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal

extension MTLDevice {
    func makeNoiseTexture(width: Int, height: Int) -> MTLTexture {
        let data = (0..<width*height*2).map { _ in UInt16(Rand(1 << 16)) }
        // unsigned normalized, so when we sample it in the shader, the values are between 0 and 1
        let texDescriptor : MTLTextureDescriptor = .texture2DDescriptor(pixelFormat: .rg16Unorm, width: width, height: height, mipmapped: false)
        let texture = makeTexture(descriptor: texDescriptor)
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.replace(region: region, mipmapLevel: 0, withBytes: data, bytesPerRow: width * 2 * 2)
        return texture
    }
}

