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

public extension MTLTexture {
    var bitsPerComponent: Int {
        get {
            switch pixelFormat {
            case .rgba16Unorm:
                return 16
            default:
                return 8
            }
        }
    }
    var bitsPerPixel: Int {
        get {
            switch pixelFormat {
            case .rgba16Unorm:
                return 64
            default:
                return 32
            }
        }
    }
    var bytesPerPixel: Int {
        get {
            return bitsPerPixel / 8
        }
    }
    var bytesPerRow: Int {
        get {
            return width * bytesPerPixel
        }
    }
    var defaultColorSpace: CGColorSpace? {
        get {
            switch pixelFormat {
            case .rgba16Unorm:
                return CGColorSpace(name: CGColorSpace.displayP3)
            default:
                return CGColorSpaceCreateDeviceRGB()
            }
        }
    }
    func dataProviderRef() -> CGDataProvider? {
        let pixelCount = width * height
        var imageBytes = [UInt8](repeating: 0, count: pixelCount * 4)
        return CGDataProvider(data: NSData(bytes: &imageBytes, length: pixelCount * 4 * MemoryLayout<UInt8>.size))
    }
}
