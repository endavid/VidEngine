//
//  Color.swift
//  metaltest
//
//  Created by David Gavilan on 6/23/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import UIKit
import simd

extension UIColor {
    convenience init(argb: UInt32) {
        let alpha = CGFloat(0x000000FF & (argb >> 24)) / 255.0
        let red = CGFloat(0x000000FF & (argb >> 16)) / 255.0
        let green = CGFloat(0x000000FF & (argb >> 8)) / 255.0
        let blue = CGFloat(0x000000FF & argb) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    var argb : UInt32 {
        get {
            var fRed : CGFloat = 0
            var fGreen : CGFloat = 0
            var fBlue : CGFloat = 0
            var fAlpha : CGFloat = 0
            self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha)
            let alpha = UInt32(255.0 * fAlpha)
            let red = UInt32(255.0 * fRed)
            let green = UInt32(255.0 * fGreen)
            let blue = UInt32(255.0 * fBlue)
            return (alpha << 24 | red << 16 | green << 8 | blue)
        }
    }
    var rgba : UInt32 {
        get {
            var fRed : CGFloat = 0
            var fGreen : CGFloat = 0
            var fBlue : CGFloat = 0
            var fAlpha : CGFloat = 0
            self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha)
            let alpha = UInt32(255.0 * fAlpha)
            let red = UInt32(255.0 * fRed)
            let green = UInt32(255.0 * fGreen)
            let blue = UInt32(255.0 * fBlue)
            return (red << 24 | green << 16 | blue << 8 | alpha)
        }
    }
}
/// A 3-channel color with an alpha channel
public protocol ColorWithAlpha {
    var raw: float4 { get }
    var rgba16U: UInt64 { get }
}

// linear RGB with alpha
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

/// sRGB color with alpha, where every channel is normalized between 0 and 1
/// Transforms use the 2.4 exponent. See https://en.wikipedia.org/wiki/SRGB
public struct NormalizedSRGBA: ColorWithAlpha {
    public let raw : float4
    
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
    public init(rgb: float3, a: Float = 1.0) {
        raw = float4(rgb.x, rgb.y, rgb.z, a)
    }
    
    public init(rgba: LinearRGBA) {
        let f = {(c: Float) -> Float in
            if c <= 0.0031308 {
                return c * 12.92
            }
            return powf(c * 1.055, 1/2.4) - 0.055
        }
        self.raw = float4(f(rgba.r), f(rgba.g), f(rgba.b), rgba.a)
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

public struct CieXYZ {
    public static let zero = CieXYZ(x: 0, y: 0, z: 0)
    public let xyz : float3
    public var x : Float {
        get {
            return xyz.x
        }
    }
    public var y : Float {
        get {
            return xyz.y
        }
    }
    public var z : Float {
        get {
            return xyz.z
        }
    }
    public init(x: Float, y: Float, z: Float) {
        xyz = float3(x, y, z)
    }
    public init(xyz: float3) {
        self.xyz = xyz
    }
    public func toRGBA(colorSpace: RGBColorSpace) -> LinearRGBA {
        let m = colorSpace.toRGB
        let rgb = m * xyz
        return LinearRGBA(rgb: rgb)
    }
}

public struct CiexyY {
    public let xyY: float3
    public var x: Float {
        get {
            return xyY.x
        }
    }
    public var y: Float {
        get {
            return xyY.y
        }
    }
    public var Y: Float {
        get {
            return xyY.z
        }
    }
    public var xyz: CieXYZ {
        get {
            if IsClose(x, 0) {
                return .zero
            }
            return CieXYZ(x: x*Y/y, y: Y, z: (1-x-y)*Y/y)
        }
    }
    public init(x: Float, y: Float, Y: Float = 1) {
        xyY = float3(x, y, Y)
    }
}

/// https://en.wikipedia.org/wiki/Standard_illuminant#White_points_of_standard_illuminants
public typealias ReferenceWhite = CiexyY
extension ReferenceWhite {
    public static let D50 = ReferenceWhite(x: 0.34567, y: 0.35850, Y: 1)
    public static let D65 = ReferenceWhite(x: 0.31271, y: 0.32902, Y: 1)
}

public struct RGBColorSpace {
    public static let dciP3 = RGBColorSpace(
        red: CiexyY(x: 0.680, y: 0.320),
        green: CiexyY(x: 0.265, y: 0.690),
        blue: CiexyY(x: 0.150, y: 0.060),
        white: .D65)
    // http://www.brucelindbloom.com/index.html?WorkingSpaceInfo.html
    public static let sRGB = RGBColorSpace(
        // primaries adapted to D50
        red: CiexyY(x: 0.648431, y: 0.330856, Y: 0.222491),
        green: CiexyY(x: 0.321152, y: 0.597871, Y: 0.716888),
        blue: CiexyY(x: 0.155886, y: 0.066044, Y: 0.060621),
        white: .D50)
    public let toXYZ: float3x3
    public let toRGB: float3x3
    public init(red: CiexyY, green: CiexyY, blue: CiexyY, white: ReferenceWhite) {
        // init with columns
        let m = float3x3([red.xyz.xyz, green.xyz.xyz, blue.xyz.xyz])
        let im = m.inverse
        let s = im * white.xyz.xyz
        toXYZ = float3x3([red.xyz.xyz * s.x, green.xyz.xyz * s.y, blue.xyz.xyz * s.z])
        toRGB = toXYZ.inverse
    }
}

public class Spectrum {
    fileprivate let data : [Int : Float]
    fileprivate let sortedKeys : [Int]
    
    public init(data: [Int : Float]) {
        self.data = data
        let keys : [Int] = Array(data.keys)
        sortedKeys = keys.sorted { $0 < $1 }
    }
    
    // linearly interpolate between the closest wavelengths (in nm)
    public func getIntensity(_ wavelength: Int) -> Float {
        // exact match
        if let me = data[wavelength] {
            return me
        }
        // clamp
        if wavelength < sortedKeys.first! {
            return data[sortedKeys.first!]!
        }
        if wavelength > sortedKeys.last! {
            return data[sortedKeys.last!]!
        }
        // interpolate
        let i1 = sortedKeys.binarySearch { wavelength > $0 }
        let i0 = (i1 - 1)
        let w1 = sortedKeys[i1]
        let w0 = sortedKeys[i0]
        let alpha = Float(wavelength - w0) / Float(w1 - w0)
        let m1 = data[w1]!
        let m0 = data[w0]!
        return (1-alpha) * m0 + alpha * m1
    }
    
    // http://www.fourmilab.ch/documents/specrend/
    public func toXYZ() -> CieXYZ {
        /* CIE colour matching functions xBar, yBar, and zBar for
         wavelengths from 380 through 780 nanometers, every 5
         nanometers.  For a wavelength lambda in this range:
         
         cie_colour_match[(lambda - 380) / 5][0] = xBar
         cie_colour_match[(lambda - 380) / 5][1] = yBar
         cie_colour_match[(lambda - 380) / 5][2] = zBar
         */
        let cieColourMatch : [float3] = [
            float3(0.0014,0.0000,0.0065), float3(0.0022,0.0001,0.0105), float3(0.0042,0.0001,0.0201),
            float3(0.0076,0.0002,0.0362), float3(0.0143,0.0004,0.0679), float3(0.0232,0.0006,0.1102),
            float3(0.0435,0.0012,0.2074), float3(0.0776,0.0022,0.3713), float3(0.1344,0.0040,0.6456),
            float3(0.2148,0.0073,1.0391), float3(0.2839,0.0116,1.3856), float3(0.3285,0.0168,1.6230),
            float3(0.3483,0.0230,1.7471), float3(0.3481,0.0298,1.7826), float3(0.3362,0.0380,1.7721),
            float3(0.3187,0.0480,1.7441), float3(0.2908,0.0600,1.6692), float3(0.2511,0.0739,1.5281),
            float3(0.1954,0.0910,1.2876), float3(0.1421,0.1126,1.0419), float3(0.0956,0.1390,0.8130),
            float3(0.0580,0.1693,0.6162), float3(0.0320,0.2080,0.4652), float3(0.0147,0.2586,0.3533),
            float3(0.0049,0.3230,0.2720), float3(0.0024,0.4073,0.2123), float3(0.0093,0.5030,0.1582),
            float3(0.0291,0.6082,0.1117), float3(0.0633,0.7100,0.0782), float3(0.1096,0.7932,0.0573),
            float3(0.1655,0.8620,0.0422), float3(0.2257,0.9149,0.0298), float3(0.2904,0.9540,0.0203),
            float3(0.3597,0.9803,0.0134), float3(0.4334,0.9950,0.0087), float3(0.5121,1.0000,0.0057),
            float3(0.5945,0.9950,0.0039), float3(0.6784,0.9786,0.0027), float3(0.7621,0.9520,0.0021),
            float3(0.8425,0.9154,0.0018), float3(0.9163,0.8700,0.0017), float3(0.9786,0.8163,0.0014),
            float3(1.0263,0.7570,0.0011), float3(1.0567,0.6949,0.0010), float3(1.0622,0.6310,0.0008),
            float3(1.0456,0.5668,0.0006), float3(1.0026,0.5030,0.0003), float3(0.9384,0.4412,0.0002),
            float3(0.8544,0.3810,0.0002), float3(0.7514,0.3210,0.0001), float3(0.6424,0.2650,0.0000),
            float3(0.5419,0.2170,0.0000), float3(0.4479,0.1750,0.0000), float3(0.3608,0.1382,0.0000),
            float3(0.2835,0.1070,0.0000), float3(0.2187,0.0816,0.0000), float3(0.1649,0.0610,0.0000),
            float3(0.1212,0.0446,0.0000), float3(0.0874,0.0320,0.0000), float3(0.0636,0.0232,0.0000),
            float3(0.0468,0.0170,0.0000), float3(0.0329,0.0119,0.0000), float3(0.0227,0.0082,0.0000),
            float3(0.0158,0.0057,0.0000), float3(0.0114,0.0041,0.0000), float3(0.0081,0.0029,0.0000),
            float3(0.0058,0.0021,0.0000), float3(0.0041,0.0015,0.0000), float3(0.0029,0.0010,0.0000),
            float3(0.0020,0.0007,0.0000), float3(0.0014,0.0005,0.0000), float3(0.0010,0.0004,0.0000),
            float3(0.0007,0.0002,0.0000), float3(0.0005,0.0002,0.0000), float3(0.0003,0.0001,0.0000),
            float3(0.0002,0.0001,0.0000), float3(0.0002,0.0001,0.0000), float3(0.0001,0.0000,0.0000),
            float3(0.0001,0.0000,0.0000), float3(0.0001,0.0000,0.0000), float3(0.0000,0.0000,0.0000)
        ]
        
        var lambda : Int = 380
        var xyz = float3(0,0,0)
        for i in 0..<cieColourMatch.count {
            let me = getIntensity(lambda)
            xyz = xyz + me * cieColourMatch[i]
            lambda += 5
        }
        let sum = xyz.x + xyz.y + xyz.z
        xyz = (1 / sum) * xyz
        return CieXYZ(xyz: xyz)
    }
}
