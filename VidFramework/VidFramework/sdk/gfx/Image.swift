//
//  Image.swift
//
//  Created by David Gavilan on 6/23/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal

func createNoiseTexture(device: MTLDevice, width: Int, height: Int) -> MTLTexture {
    // initialize buffer with random numbers (we'll use 2 channels)
    var data = [UInt16](repeating: 0, count: width*height*2)
    for i in 0..<data.count {
        data[i] = UInt16(Rand(1 << 16))
    }
    // unsigned normalized, so when we sample it in the shader, the values are between 0 and 1
    let texDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rg16Unorm, width: width, height: height, mipmapped: false)
    let texture = device.makeTexture(descriptor: texDescriptor)
    let region = MTLRegionMake2D(0, 0, width, height)
    texture?.replace(region: region, mipmapLevel: 0, withBytes: data, bytesPerRow: width * 2 * 2)
    return texture!
}

extension UIImage {
    convenience init?(texture: MTLTexture) {
        let bitsPerComponent = 8
        let bitsPerPixel = 32
        let bytesPerRow = Int(texture.width * 4)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo:CGBitmapInfo = [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)]
        
        guard let provider = Texture.dataProviderRef(from: texture) else {
            return nil
        }
        guard let cgim = CGImage(
            width: texture.width,
            height: texture.height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: bytesPerRow,
            space: rgbColorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
            )
        else {
            return nil
        }
        self.init(cgImage: cgim)
    }
}
