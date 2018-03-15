//
//  CiexyY.swift
//  VidFramework
//
//  Created by David Gavilan on 2018/03/15.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import simd

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
