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
            case .rgba16Float:
                return 16
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
            case .rgba16Float:
                return 64
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
    var pixelCount: Int {
        get {
            if textureType == .typeCube {
                return 6 * width * height
            }
            return width * height
        }
    }
    /// This is the height as an UIImage. It's the same as `height`, except for cubemaps, where it's `6 * height`
    var imageHeight: Int {
        get {
            if textureType == .typeCube {
                return 6 * height
            }
            return height
        }
    }
    var defaultColorSpace: CGColorSpace? {
        get {
            switch pixelFormat {
            case .rgba16Float:
                return CGColorSpace(name: CGColorSpace.linearSRGB)
            case .rgba16Unorm:
                return CGColorSpace(name: CGColorSpace.displayP3)
            default:
                return CGColorSpaceCreateDeviceRGB()
            }
        }
    }
    var cgBitmapInfo: CGBitmapInfo {
        get {
            let alphaIsLast = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)
            switch pixelFormat {
            case .rgba16Float:
                return [.byteOrder16Little, .floatComponents, alphaIsLast]
            case .rgba16Unorm:
                return [.byteOrder16Little, alphaIsLast]
            default:
                // rgba8
                return [.byteOrder32Big, alphaIsLast]
            }
        }
    }
    func readAllBytes() -> [UInt8] {
        var imageBytes = [UInt8](repeating: 0, count: pixelCount * bytesPerPixel)
        let region = MTLRegionMake2D(0, 0, width, height)
        imageBytes.withUnsafeMutableBytes { ptr in
            // getBytes will silently return nothing if the texture is not ready!
            // https://forums.developer.apple.com/thread/30488
            if textureType == .typeCube {
                let bytesPerImage = width * height * bytesPerPixel
                for i in 0..<6 {
                    getBytes(ptr.baseAddress!.advanced(by: i * bytesPerImage), bytesPerRow: bytesPerRow, bytesPerImage: bytesPerImage, from: region, mipmapLevel: 0, slice: i)
                }
            } else {
                getBytes(ptr.baseAddress!, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
            }
        }
        return imageBytes
    }
    func dataProviderRef() -> CGDataProvider? {
        var imageBytes = readAllBytes()
        return CGDataProvider(data: NSData(bytes: &imageBytes, length: pixelCount * bytesPerPixel * MemoryLayout<UInt8>.size))
    }
}
