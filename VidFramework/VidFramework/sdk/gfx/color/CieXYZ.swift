//
//  CieXYZ.swift
//  VidFramework
//
//  Created by David Gavilan on 2018/03/15.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import simd

public struct CieXYZ {
    public static let zero = CieXYZ(x: 0, y: 0, z: 0)
    public let xyz : simd_float3
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
        xyz = simd_float3(x, y, z)
    }
    public init(xyz: simd_float3) {
        self.xyz = xyz
    }
    public init(rgb: LinearRGBA, colorSpace: RGBColorSpace) {
        xyz = colorSpace.toXYZ * rgb.rgb
    }
}

public extension LinearRGBA {
    init(xyz: CieXYZ, colorSpace: RGBColorSpace) {
        let m = colorSpace.toRGB
        let rgb = m * xyz.xyz
        raw = simd_float4(rgb.x, rgb.y, rgb.z, 1.0)
    }
}
