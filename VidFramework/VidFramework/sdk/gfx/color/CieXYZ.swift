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
