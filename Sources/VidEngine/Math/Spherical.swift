//
//  Spherical.swift
//  VidEngine
//
//  Created by David Gavilan on 8/21/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import simd

public struct Spherical {
    /// Radial distance
    public let r: Float
    /// Inclination (theta) {0,π}
    public let θ: Float
    /// Azimuth (phi) {0,2π}
    public let φ: Float
    
    // Maybe I'll hate myself later for using symbols 😂
    // (they aren't difficult to type with Japanese input, type シータ and ファイ)
    public init (r: Float, θ: Float, φ: Float) {
        self.r = r
        self.θ = θ
        self.φ = φ
    }
    
    /// Converts from Cartesian to Spherical coordinates
    public init (v: simd_float3) {
        r = length(v)
        θ = acosf(v.y / r)
        // convert -pi..pi to 0..2pi
        let phi = atan2f(v.x, v.z)
        φ = phi < 0 ? PI2 + phi : phi
    }
    
    public init () {
        r = 1
        θ = 0
        φ = 0
    }
    
    public func toCartesian() -> simd_float3 {
        return r * simd_float3(sinf(θ) * sinf(φ), cosf(θ), sinf(θ) * cos(φ))
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
