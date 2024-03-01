//
//  WideColor.swift
//  VidFramework
//
//  Created by David Gavilan on 2018/03/30.
//

import simd

/// Utils to map normalized linear P3 RGB color to the extended sRGB
/// range used in bgra10 textures, and viceversa
/// https://developer.apple.com/documentation/metal/mtlpixelformat/1650026-bgra10_xr
public class WideColor {
    public static func toSrgb() -> float4x4 {
        let m = RGBColorSpace.sRGB.toRGB * RGBColorSpace.dciP3.toXYZ
        let colorTransform = float4x4([
            simd_float4(m[0].x, m[0].y, m[0].z, 0),
            simd_float4(m[1].x, m[1].y, m[1].z, 0),
            simd_float4(m[2].x, m[2].y, m[2].z, 0),
            simd_float4(0, 0, 0, 1),
            ])
        return colorTransform
    }
    public static func toDciP3() -> float4x4 {
        let m = RGBColorSpace.dciP3.toRGB * RGBColorSpace.sRGB.toXYZ
        let colorTransform = float4x4([
            simd_float4(m[0].x, m[0].y, m[0].z, 0),
            simd_float4(m[1].x, m[1].y, m[1].z, 0),
            simd_float4(m[2].x, m[2].y, m[2].z, 0),
            simd_float4(0, 0, 0, 1),
            ])
        return colorTransform
    }
}
