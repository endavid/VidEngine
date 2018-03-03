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
    public init(device: MTLDevice, id: String, width: Int, height: Int, data: [UInt64], usage: MTLTextureUsage = [.shaderRead]) {
        self.init(device: device, id: id, width: width, height: height, pixelFormat: .rgba16Unorm, data: data, bytesPerPixel: 8, usage: usage)
    }
    public init(device: MTLDevice, id: String, width: Int, height: Int, data: [UInt32], usage: MTLTextureUsage = [.shaderRead]) {
        self.init(device: device, id: id, width: width, height: height, pixelFormat: .rgba8Unorm, data: data, bytesPerPixel: 4, usage: usage)
    }
    init(device: MTLDevice, id: String, width: Int, height: Int, pixelFormat: MTLPixelFormat, data: UnsafeRawPointer, bytesPerPixel: Int, usage: MTLTextureUsage) {
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
    public func readAllBytes() -> [UInt8] {
        let pixelCount = width * height
        var imageBytes = [UInt8](repeating: 0, count: pixelCount * bytesPerPixel)
        let region = MTLRegionMake2D(0, 0, width, height)
        getBytes(&imageBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        return imageBytes
    }
    func dataProviderRef() -> CGDataProvider? {
        let pixelCount = width * height
        var imageBytes = readAllBytes()
        return CGDataProvider(data: NSData(bytes: &imageBytes, length: pixelCount * bytesPerPixel * MemoryLayout<UInt8>.size))
    }
}
