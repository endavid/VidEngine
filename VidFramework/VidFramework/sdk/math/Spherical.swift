//
//  Spherical.swift
//  VidEngine
//
//  Created by David Gavilan on 8/21/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import simd

public class Spherical {
    public var r       : Float = 1     ///< Radial distance
    public var θ       : Float = 0     ///< Inclination (theta) {0,π}
    public var φ       : Float = 0     ///< Azimuth (phi) {0,2π}

    // Maybe I'll hate myself later for using symbols 😂
    // (they aren't difficult to type with Japanese input, type シータ and ファイ)
    public init (r: Float, θ: Float, φ: Float) {
        self.r = r
        self.θ = θ
        self.φ = φ
    }

    /// Converts from Cartesian to Spherical coordinates
    public init (v: float3) {
        r = length(v)
        θ = acosf(v.y / r)
        // convert -pi..pi to 0..2pi
        φ = atan2f(v.x, v.z)
        φ = φ < 0 ? PI2 + φ : φ
    }

    public init () {
    }

    public func toCartesian() -> float3 {
        return float3(r * sinf(θ) * sinf(φ), r * cosf(θ), r * sinf(θ) * cos(φ))
    }

    public static func randomSample() -> Spherical {
        let x = Double(Randf())
        let y = Double(Randf())
        let θ = 2.0 * acos(sqrt(1.0 - x))
        let φ = 2.0 * π * y
        let sph = Spherical(r: 1.0, θ: Float(θ), φ: Float(φ))
        return sph
    }
}
