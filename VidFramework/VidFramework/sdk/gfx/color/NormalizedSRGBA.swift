//
//  NormalizedSRGBA.swift
//  VidFramework
//
//  Created by David Gavilan on 2018/03/15.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import simd

/// sRGB color with alpha, where every channel is normalized between 0 and 1
/// Transforms use the 2.4 exponent. See https://en.wikipedia.org/wiki/SRGB
public struct NormalizedSRGBA: ColorWithAlpha {
    public let raw : simd_float4
    
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
    public var uiColor: UIColor {
        get {
            // @todo use displayP3 if any channel is out of 0..1 bounds
            let c = UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(a))
            return c
        }
    }
    public init(r: Float, g: Float, b: Float, a: Float) {
        raw = simd_float4(r, g, b, a)
    }
    public init(rgb: simd_float3, a: Float = 1.0) {
        raw = simd_float4(rgb.x, rgb.y, rgb.z, a)
    }
    
    public init(rgba: LinearRGBA) {
        let f = {(c: Float) -> Float in
            if abs(c) <= 0.0031308 {
                return c * 12.92
            }
            return sign(c) * (powf(abs(c), 1/2.4) * 1.055 - 0.055)
        }
        self.raw = simd_float4(f(rgba.r), f(rgba.g), f(rgba.b), rgba.a)
    }
    
    public init(_ color: UIColor) {
        var fRed : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue : CGFloat = 0
        var fAlpha : CGFloat = 0
        color.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha)
        self.init(r: Float(fRed), g: Float(fGreen), b: Float(fBlue), a: Float(fAlpha))
    }
    
}
