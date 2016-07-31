//
//  Image.swift
//
//  Created by David Gavilan on 6/23/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import UIKit

func createNoiseTexture(device device: MTLDevice, width: Int, height: Int) -> MTLTexture {
    // initialize buffer with random numbers (we'll use 2 channels)
    var data = [UInt16](count: width*height*2, repeatedValue: 0)
    for i in 0..<data.count {
        data[i] = UInt16(Rand(1 << 16))
    }
    // unsigned normalized, so when we sample it in the shader, the values are between 0 and 1
    let texDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.RG16Unorm, width: width, height: height, mipmapped: false)
    let texture = device.newTextureWithDescriptor(texDescriptor)
    let region = MTLRegionMake2D(0, 0, width, height)
    texture.replaceRegion(region, mipmapLevel: 0, withBytes: data, bytesPerRow: width * 2 * 2)
    return texture
}

