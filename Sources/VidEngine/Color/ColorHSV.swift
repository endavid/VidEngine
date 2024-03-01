//
//  ColorHSV.swift
//  VidFramework
//
//  Created by David Gavilan on 2018/04/29.
//

import simd

/// HSV color with alpha
/// Hue is specified in degrees, between 0 and 360
/// and Saturation and Value, between 0 and 1
/// https://en.wikipedia.org/wiki/HSL_and_HSV
public struct ColorHSV {
    public let raw: simd_float4
    public var h: Float {
        get {
            return raw.x
        }
    }
    public var s: Float {
        get {
            return raw.y
        }
    }
    public var v: Float {
        get {
            return raw.z
        }
    }
    public var a: Float {
        get {
            return raw.w
        }
    }
    public var hsv: simd_float3 {
        get {
            return simd_float3(h, s, v)
        }
    }
    public var rgb: simd_float3 {
        get {
            let chroma = v * s
            let h_ = h / 60
            let x = chroma * (1 - abs(fmod(h_,2) - 1))
            var r1: Float = 0
            var g1: Float = 0
            var b1: Float = 0
            if h_ <= 1 {
                r1 = chroma
                g1 = x
            } else if h_ <= 2 {
                r1 = x
                g1 = chroma
            } else if h_ <= 3 {
                g1 = chroma
                b1 = x
            } else if h_ <= 4 {
                g1 = x
                b1 = chroma
            } else if h_ <= 5 {
                r1 = x
                b1 = chroma
            } else {
                r1 = chroma
                b1 = x
            }
            let m = v - chroma
            return simd_float3(r1 + m, g1 + m, b1 + m)
        }
    }
    public init(h: Float, s: Float, v: Float, a: Float = 1) {
        raw = simd_float4(h, s, v, a)
    }
    public init(hsv: simd_float3, a: Float = 1.0) {
        raw = simd_float4(hsv.x, hsv.y, hsv.z, a)
    }
    public init(rgb: simd_float3, a: Float = 1.0) {
        let r = rgb.x, g = rgb.y, b = rgb.z
        let M = max(r, g, b)
        let m = min(r, g, b)
        let chroma = M - m
        var h_: Float = 0
        if !IsClose(chroma, 0) {
            if IsClose(M, r) {
                h_ = fmod((g - b)/chroma, 6)
            } else if IsClose(M, g) {
                h_ = (b - r) / chroma + 2
            } else {
                h_ = (r - g) / chroma + 4
            }
        }
        let h = 60 * h_
        let v = M
        var s: Float = 0
        if !IsClose(0, v) {
            s = chroma / v
        }
        raw = simd_float4(h, s, v, a)
    }
}
