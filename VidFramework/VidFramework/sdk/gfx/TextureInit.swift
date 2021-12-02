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
    init(device: MTLDevice, id: String, width: Int, height: Int, data: [UInt64], usage: MTLTextureUsage = [.shaderRead], isLinear: Bool? = nil) {
        self.init(device: device, id: id, width: width, height: height, pixelFormat: .rgba16Unorm, data: data, bytesPerPixel: 8, usage: usage, isLinear: isLinear)
    }
    init(device: MTLDevice, id: String, width: Int, height: Int, data: [UInt32], usage: MTLTextureUsage = [.shaderRead], isLinear: Bool? = nil) {
        self.init(device: device, id: id, width: width, height: height, pixelFormat: .rgba8Unorm, data: data, bytesPerPixel: 4, usage: usage, isLinear: isLinear)
    }
    init(device: MTLDevice, id: String, width: Int, height: Int, pixelFormat: MTLPixelFormat, data: UnsafeRawPointer, bytesPerPixel: Int, usage: MTLTextureUsage, isLinear: Bool?) {
        self.id = id
        let texDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: width, height: height, mipmapped: false)
        texDescriptor.usage = usage
        if let texture = device.makeTexture(descriptor: texDescriptor) {
            let region = MTLRegionMake2D(0, 0, width, height)
            texture.replace(region: region, mipmapLevel: 0, withBytes: data, bytesPerRow: bytesPerPixel * width)
            mtlTexture = texture
        } else {
            mtlTexture = nil
        }
        self.isLinear = isLinear ?? Texture.guessLinear(pixelFormat)
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
            let n = width * bytesPerPixel
            if textureType == .typeCube {
                return 6 * n
            }
            return n
        }
    }
    var pixelCount: Int {
        get {
            if textureType == .typeCube {
                return 6 * width * height
            }
            return width * height
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
    func readAllBytes() -> [UInt8] {
        var imageBytes = [UInt8](repeating: 0, count: pixelCount * bytesPerPixel)
        let region = MTLRegionMake2D(0, 0, width, height)
        // getBytes will silently return nothing if the texture is not ready!
        // https://forums.developer.apple.com/thread/30488
        getBytes(&imageBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        return imageBytes
    }
    func dataProviderRef() -> CGDataProvider? {
        var imageBytes = readAllBytes()
        return CGDataProvider(data: NSData(bytes: &imageBytes, length: pixelCount * bytesPerPixel * MemoryLayout<UInt8>.size))
    }
}
