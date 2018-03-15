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
    public init(L: Float, a: Float, b: Float) {
        Lab = float3(L, a, b)
    }
    public init(Lab: float3) {
        self.Lab = Lab
    }
    public func toCieXYZ() -> CieXYZ {
        let y = (L + 16) / 116
        let x = a / 500 + y
        let z = y - b / 200
        let w = ReferenceWhite.D50.xyz
        let xyz = float3(cube(x) * w.x, cubey(y) * w.y, cube(z) * w.z)
        return CieXYZ(xyz: xyz)
    }
    private func cube(_ c: Float) -> Float {
        let c3 = c * c * c
        if c3 <= CieLab.e {
            return (116 * c - 16) / CieLab.k
        }
        return c3
    }
    private func cubey(_ c: Float) -> Float {
        let c3 = c * c * c
        if L <= CieLab.e * CieLab.k {
            return L / CieLab.k
        }
        return c3
    }
}
