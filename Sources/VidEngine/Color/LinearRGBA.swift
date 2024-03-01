//
//  LinearRGBA.swift
//  VidFramework
//
//  Created by David Gavilan on 2018/03/15.
//

#if canImport(UIKit)
import UIKit
#else
import Cocoa
#endif
import simd

/// Linear RGB with alpha
public struct LinearRGBA: ColorWithAlpha {
    public static let white = LinearRGBA(r: 1,g: 1,b: 1,a: 1)
    public static let black = LinearRGBA(r: 0,g: 0,b: 0,a: 1)
    public static let transparent = LinearRGBA(r: 0,g: 0,b: 0,a: 0)
    public let raw: simd_float4
    
    static func toUInt32(_ rgba: simd_float4) -> UInt32 {
        let r = UInt32((Float(0xFF) * rgba.x).rounded())
        let g = UInt32((Float(0xFF) * rgba.y).rounded())
        let b = UInt32((Float(0xFF) * rgba.z).rounded())
        let a = UInt32((Float(0xFF) * rgba.w).rounded())
        return (a << 24 | b << 16 | g << 8 | r)
    }
    static func toUInt64(_ rgba: simd_float4) -> UInt64 {
        let r = UInt64((Float(0xFFFF) * rgba.x).rounded())
        let g = UInt64((Float(0xFFFF) * rgba.y).rounded())
        let b = UInt64((Float(0xFFFF) * rgba.z).rounded())
        let a = UInt64((Float(0xFFFF) * rgba.w).rounded())
        // the order for a rgba16u texture is ABGR
        return (a << 48 | b << 32 | g << 16 | r)
    }
    
    public var r : Float {
        get {
            return raw.x
        }
    }
    public var g : Float {
        get {
            return raw.y
        }
    }
    public var b : Float {
        get {
            return raw.z
        }
    }
    public var a : Float {
        get {
            return raw.w
        }
    }
    public var rgb: simd_float3 {
        get {
            return simd_float3(r, g, b)
        }
    }
    public var color: simd_float3 {
        get {
            return rgb
        }
    }
    public var rgba8U: UInt32 {
        get {
            return LinearRGBA.toUInt32(raw)
        }
    }
    public var rgba16U: UInt64 {
        get {
            return LinearRGBA.toUInt64(raw)
        }
    }
    
    public init(r: Float, g: Float, b: Float, a: Float) {
        raw = simd_float4(r, g, b, a)
    }
    
    public init(rgb: simd_float3, a: Float = 1.0) {
        raw = simd_float4(rgb.x, rgb.y, rgb.z, a)
    }
    
    public init(srgba: NormalizedSRGBA) {
        let f = {(c: Float) -> Float in
            if abs(c) <= 0.04045 {
                return c / 12.92
            }
            return sign(c) * powf((abs(c) + 0.055) / 1.055, 2.4)
        }
        raw = simd_float4(f(srgba.r), f(srgba.g), f(srgba.b), srgba.a)
    }

#if canImport(UIKit)
    /// When using a UIColor, the inverse gamma will be applied and
    /// the color converted to linear RGB.
    public init(_ color: UIColor) {
        let sRGB = NormalizedSRGBA(color)
        self.init(srgba: sRGB)
    }
#else
    /// When using a NSColor, the inverse gamma will be applied and
    /// the color converted to linear RGB.
    public init(_ color: NSColor) {
        let sRGB = NormalizedSRGBA(color)
        self.init(srgba: sRGB)
    }
#endif
}
