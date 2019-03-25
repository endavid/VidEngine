//
//  CieLab.swift
//  VidFramework
//
//  Created by David Gavilan on 2018/03/14.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import simd

public struct CieLab {
    private static let e: Float = 216/24389
    private static let k: Float = 24389/27

    public let Lab: float3
    public var L: Float {
        get { return Lab.x }
    }
    public var a: Float {
        get { return Lab.y }
    }
    public var b: Float {
        get { return Lab.z }
    }
    public var rgba16U: UInt64 {
        get {
            return LinearRGBA.toUInt64(float4(L/100, 0.5 + 0.5*a/128, 0.5 + 0.5*b/128, 1.0))
        }
    }
    
    public init(L: Float, a: Float, b: Float) {
        Lab = float3(L, a, b)
    }
    public init(Lab: float3) {
        self.Lab = Lab
    }
    public init(xyz: CieXYZ) {
        let w = ReferenceWhite.D50.xyz
        let r = float3(xyz.x / w.x, xyz.y / w.y, xyz.z / w.z)
        let f = float3(CieLab.cubicRoot(r.x), CieLab.cubicRoot(r.y), CieLab.cubicRoot(r.z))
        Lab = float3(116 * f.y - 16, 500 * (f.x - f.y), 200 * (f.y - f.z))
    }
    private static func cubicRoot(_ c: Float) -> Float {
        if c <= CieLab.e {
            return (CieLab.k * c + 16) / 116
        }
        return powf(c, 1/3)
    }
    func cube(_ c: Float) -> Float {
        let c3 = c * c * c
        if c3 <= CieLab.e {
            return (116 * c - 16) / CieLab.k
        }
        return c3
    }
    func cubey(_ c: Float) -> Float {
        let c3 = c * c * c
        if L <= CieLab.e * CieLab.k {
            return L / CieLab.k
        }
        return c3
    }
}

public extension CieXYZ {
    init(Lab: CieLab) {
        let y = (Lab.L + 16) / 116
        let x = Lab.a / 500 + y
        let z = y - Lab.b / 200
        let w = ReferenceWhite.D50.xyz
        xyz = float3(Lab.cube(x) * w.x, Lab.cubey(y) * w.y, Lab.cube(z) * w.z)
    }
}
