//
//  LinearRGBA.swift
//  VidFramework
//
//  Created by David Gavilan on 2018/03/15.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import simd

/// Linear RGB with alpha
public struct LinearRGBA: ColorWithAlpha {
    public let raw: float4
    
    static func toUInt64U(_ rgba: float4) -> UInt64 {
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
    public var rgb: float3 {
        get {
            return float3(r, g, b)
        }
    }
    public var rgba16U: UInt64 {
        get {
            return LinearRGBA.toUInt64U(raw)
        }
    }
    
    public init(r: Float, g: Float, b: Float, a: Float) {
        raw = float4(r, g, b, a)
    }
    
    public init(rgb: float3, alpha: Float = 1.0) {
        raw = float4(rgb.x, rgb.y, rgb.z, alpha)
    }
    
    public init(srgba: NormalizedSRGBA) {
        let f = {(c: Float) -> Float in
            if c <= 0.04045 {
                return c / 12.92
            }
            return powf((c + 0.055) / 1.055, 2.4)
        }
        raw = float4(f(srgba.r), f(srgba.g), f(srgba.b), srgba.a)
    }
    
    /// When using a UIColor, the inverse gamma will be applied and
    /// the color converted to linear RGB.
    public init(_ color: UIColor) {
        let sRGB = NormalizedSRGBA(color)
        self.init(srgba: sRGB)
    }
}
