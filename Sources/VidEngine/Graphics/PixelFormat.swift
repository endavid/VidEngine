//
//  PixelFormat.swift
//  VidEngine
//
//  Created by David Gavilan Ruiz on 19/06/2025.
//
import MetalKit

extension MTLPixelFormat {
    var asString: String {
        let formatStrings: [MTLPixelFormat: String] = [
            // Ordinary 8-Bit Pixel Formats
            .r8Unorm: "r8Unorm",
            // Ordinary 32-Bit Pixel Formats
            .bgra8Unorm: "bgra8Unorm",
            .bgra8Unorm_srgb: "bgra8Unorm_srgb",
            .rgba8Unorm: "rgba8Unorm",
            .rgba8Unorm_srgb: "rgba8Unorm_srgb",
            // Packed 32-bit Pixel Formats
            .bgr10a2Unorm: "bgr10a2Unorm", // macOS only
            .rgb10a2Unorm: "rgb10a2Unorm", // macOS only
            // Ordinary 64-Bit Pixel Formats
                .rgba16Float: "rgba16Float",
            .rgba16Unorm: "rgba16Unorm",
            // Normal 128 bit formats
            .rgba32Float: "rgba32Float", // .hdr images
            // Extended Range and Wide Color Pixel Formats
            .bgra10_xr: "bgra10_xr",
            .bgra10_xr_srgb: "bgra10_xr_srgb",
            .bgr10_xr: "bgr10_xr",
            .bgr10_xr_srgb: "bgr10_xr_srgb",
            // Add other cases here...
        ]
        return formatStrings[self] ?? String(describing: self)
    }
    
    var asColorSpace: CGColorSpace? {
        switch self {
        case .rgba8Unorm, .bgra8Unorm, .rgba8Unorm_srgb, .bgra8Unorm_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .bgra10_xr, .bgra10_xr_srgb, .bgr10a2Unorm, .rgb10a2Unorm:
            return CGColorSpace(name: CGColorSpace.displayP3)
        case .rgba16Unorm:
            // it could be linear SRGB, but we use it in our app for P3
            return CGColorSpace(name: CGColorSpace.displayP3)
        case .rgba16Float:
            return CGColorSpace(name: CGColorSpace.linearSRGB)
        case .rgba32Float:
            return CGColorSpace(name: CGColorSpace.extendedLinearSRGB)
        default:
            return nil
        }
    }
    
    var is_srgb: Bool {
        switch self {
        case .r8Unorm_srgb, .rgba8Unorm_srgb, .bgra8Unorm_srgb, .bgr10_xr_srgb, .bgra10_xr_srgb:
            return true
        default:
            return false
        }
    }
    
    var as_srgb: MTLPixelFormat {
        switch self {
        case .r8Unorm:
            return .r8Unorm_srgb
        case .rgba8Unorm:
            return .rgba8Unorm_srgb
        case .bgra8Unorm:
            return .bgra8Unorm_srgb
        case .bgra10_xr:
            return .bgra10_xr_srgb
        default:
            return self
        }
    }
    
    var non_srgb: MTLPixelFormat {
        switch self {
        case .r8Unorm_srgb:
            return .r8Unorm
        case .rgba8Unorm_srgb:
            return .rgba8Unorm
        case .bgra8Unorm_srgb:
            return .bgra8Unorm
        case .bgra10_xr_srgb:
            return .bgra10_xr
        default:
            return self
        }
    }
    
    /// It returns a format that it's better for export. E.g. instead of BGRA order, it's RGBA.
    var preferred_output: MTLPixelFormat {
        switch self {
        case .r8Unorm:
            return .r8Unorm
        case .rgba16Unorm, .rgba16Float, .rgba16Snorm:
            return .rgba16Unorm
        case .rgba32Float:
            return .rgba32Float
        default:
            return .rgba8Unorm
        }
    }
    
    var byteOrder: CGBitmapInfo {
        switch self {
        case .r8Unorm:
            return .byteOrderDefault
        case .rgba16Float, .rgba16Unorm:
            return .byteOrder16Little
        case .bgra10_xr, .bgra10_xr_srgb:
            return .byteOrder16Little
        case .rgba32Float:
            return .byteOrder32Little
        default:
            return .byteOrder32Big
        }
    }
    
    var isFloat: Bool {
        switch self {
        case .rgba16Float, .rgba32Float:
            return true
        default:
            return false
        }
    }
        
    var bitsPerComponent: Int {
        switch self {
        case .rgba8Unorm, .bgra8Unorm, .rgba8Unorm_srgb, .bgra8Unorm_srgb:
            return 8
        case .rgba16Unorm, .rgba16Float, .bgra10_xr_srgb, .bgra10_xr:
            return 16
        case .rgba32Float:
            return 32
        default:
            return 8
        }
    }
    
    var bytesPerPixel: Int {
        switch self {
        case .r8Unorm, .r8Unorm_srgb:
            return 1
        case .rgba8Unorm, .bgra8Unorm, .rgba8Unorm_srgb, .bgra8Unorm_srgb:
            return 4
        case .rgba16Unorm, .rgba16Float, .bgra10_xr_srgb, .bgra10_xr:
            return 8
        case .rgba32Float:
            return 16
        default:
            return 4
        }
    }
    
    var pixelSize: Int {
        return bytesPerPixel * 8
    }
}
