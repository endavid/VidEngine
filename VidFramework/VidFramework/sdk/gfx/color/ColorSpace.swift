//
//  ColorSpace.swift
//  VidFramework
//
//  Created by David Gavilan on 2018/03/15.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import simd

public struct RGBColorSpace {
    public static let dciP3 = RGBColorSpace(
        red: CieXYZ(x: 0.5151, y: 0.2412, z: -0.0011),
        green: CieXYZ(x: 0.2920, y: 0.6922, z: 0.0419),
        blue: CieXYZ(x: 0.1571, y: 0.0666, z: 0.7841))
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
    public init(red: CieXYZ, green: CieXYZ, blue: CieXYZ) {
        toXYZ = float3x3([red.xyz, green.xyz, blue.xyz])
        toRGB = toXYZ.inverse
    }
}
