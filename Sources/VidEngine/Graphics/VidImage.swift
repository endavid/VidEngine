//
//  File.swift
//  
//
//  Created by David Gavilan Ruiz on 01/03/2024.
//
import Foundation
import MetalKit
import UniformTypeIdentifiers
import Accelerate

#if canImport(UIKit)
import UIKit
typealias VidImage = UIImage
#else
import Cocoa
typealias VidImage = NSImage
extension VidImage {
    var cgImage: CGImage? {
        get {
            var rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            if let representation = representations.first {
                logDebug("createTexture: NSImage \(rect.width)x\(rect.height) pt = \(representation.pixelsWide)x\(representation.pixelsHigh) px; colorSpace: \(representation.colorSpaceName); bitsPerSample: \(representation.bitsPerSample)")
                rect = CGRect(x: 0, y: 0, width: CGFloat(representation.pixelsWide), height: CGFloat(representation.pixelsHigh))
            }
            guard let cgImage = cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
                return nil
            }
            return cgImage
        }
    }
}
#endif

/** Saves image to disk
*  @see http://stackoverflow.com/questions/1320988/saving-cgimageref-to-a-png-file
*/
@available(macOS 13.0, iOS 14.0, *)
func CGImageWriteToFile(_ image: CGImage, filename: URL) {
    let url = filename as CFURL
    guard let destination = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil) else {
        NSLog("Failed to create destination: \(url)")
        return
    }
    CGImageDestinationAddImage(destination, image, nil)
    if !CGImageDestinationFinalize(destination) {
        NSLog("Failed to write image to \(filename)")
    }
}

// https://stackoverflow.com/a/52935870
func swizzleBGRA16toRGBA16(_ bytes: UnsafeMutableRawPointer, width: Int, height: Int) {
    var sourceBuffer = vImage_Buffer(data: bytes,
                                     height: vImagePixelCount(height),
                                     width: vImagePixelCount(width),
                                     rowBytes: width * 8)
    var destBuffer = vImage_Buffer(data: bytes,
                                   height: vImagePixelCount(height),
                                   width: vImagePixelCount(width),
                                   rowBytes: width * 8)
    var swizzleMask: [UInt8] = [ 2, 1, 0, 3 ] // BGRA -> RGBA
    if #available(macOS 13.0, iOS 16.0, *) {
        vImagePermuteChannels_ARGB16F(&sourceBuffer, &destBuffer, &swizzleMask, vImage_Flags(kvImageNoFlags))
    } else {
        // Fallback on earlier versions
        logDebug("swizzleBGRA16toRGBA16 unsupported")
    }
}

func CGImageFrom(texture: MTLTexture, colorSpace: CGColorSpace) -> CGImage? {
    var bitmapInfoRaw = texture.pixelFormat.byteOrder.rawValue
    if texture.pixelFormat.bytesPerPixel >= 4 {
        bitmapInfoRaw |= CGImageAlphaInfo.last.rawValue
    }
    if texture.pixelFormat.isFloat {
        bitmapInfoRaw |= CGBitmapInfo.floatComponents.rawValue
    }
    let bitmapInfo = CGBitmapInfo(rawValue: bitmapInfoRaw)
    let width = texture.width
    let height = texture.height
    let rowBytes = width * texture.pixelFormat.bytesPerPixel

    let textureData = UnsafeMutablePointer<UInt8>.allocate(capacity: height * rowBytes)
    let bytesPerImage = height * rowBytes

    // note that CoreGraphics expects the channels in RGBA order: https://stackoverflow.com/a/52935870/1765629
    texture.getBytes(textureData,
                     bytesPerRow: rowBytes,
                     bytesPerImage: bytesPerImage,
                     from: MTLRegionMake2D(0, 0, width, height),
                     mipmapLevel: 0,
                     slice: 0)
    
    if texture.pixelFormat == .bgra10_xr_srgb || texture.pixelFormat == .bgra10_xr {
        swizzleBGRA16toRGBA16(textureData, width: width, height: height)
    }

    let providerRef = CGDataProvider(data: NSData(bytesNoCopy: textureData, length: height * rowBytes, freeWhenDone: true))

    return CGImage(width: width,
                   height: height,
                   bitsPerComponent: texture.pixelFormat.bitsPerComponent,
                   bitsPerPixel: texture.pixelFormat.pixelSize,
                   bytesPerRow: rowBytes,
                   space: colorSpace,
                   bitmapInfo: bitmapInfo,
                   provider: providerRef!,
                   decode: nil,
                   shouldInterpolate: false,
                   intent: .defaultIntent)
}
