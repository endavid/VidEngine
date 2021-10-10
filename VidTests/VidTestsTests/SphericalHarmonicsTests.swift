//
//  SphericalHarmonicsTests.swift
//  VidTestsTests
//
//  Created by David Gavilan on 2019/02/18.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import XCTest
import simd
import VidFramework
@testable import VidTests

func assertAlmostEqual(_ expected: SHSample, _ actual: SHSample) {
    assertAlmostEqual(expected.sph, actual.sph)
    assertAlmostEqual(expected.vec, actual.vec)
    assertAlmostEqual(expected.coeff, actual.coeff)
}

func checkIrradiance(_ sh: SphericalHarmonics, color: simd_float3, irradiance: simd_float3, normal: simd_float3) {
    // every run the samples are random, so we make the epsilon a bit big
    let e: Float = 0.5
    assertAlmostEqual(color, sh.reconstruct(direction: normal), epsilon: e)
    assertAlmostEqual(irradiance, sh.getIrradianceApproximation(normal: normal), epsilon: e)
}

func colorFromPolarCoordinates(θ: Float, φ: Float) -> Vec3 {
    let s = Spherical(r: 1, θ: θ, φ: φ)
    let c = s.toCartesian()
    let ax = fabsf(c.x)
    let ay = fabsf(c.y)
    let az = fabsf(c.z)
    if ay >= ax && ay >= az {
        if c.y > 0 {
            // up is cyan
            return Vec3(0, 1, 1)
        }
        // down is green
        return Vec3(0, 1, 0)
    }
    if ax >= az {
        if c.x > 0 {
            // right is red
            return Vec3(1, 0, 0)
        }
        // left is yellow
        return Vec3(1, 1, 0)
    }
    if c.z > 0 {
        // front is magenta
        return Vec3(1, 0, 1)
    }
    // back is white
    return Vec3(1, 1, 1)
}

class SphericalHarmonicsTests: XCTestCase {
    func testStorage() {
        let storage: SHStorage = SphericalHarmonicsArrays(numBands: 3, sqrtSamples: 5)
        XCTAssertEqual(3, storage.numBands)
        XCTAssertEqual(25, storage.numSamples)
        XCTAssertEqual(5, storage.sqrtSamples)
        XCTAssertEqual(9, storage.numCoeffs)
        let coefficients = [Double](repeating: 0, count: 9)
        let emptySample = SHSample(sph: Spherical(), vec: .zero, coeff: coefficients)
        assertAlmostEqual(emptySample, storage.getSample(i: 24))
        assertAlmostEqual(Vec3.zero, storage.getCoefficient(i: 8))
        assertAlmostEqual(float4x4(), storage.getIrradiance(i: 2))
    }
    func testIrradiance() {
        let storage: SHStorage = SphericalHarmonicsArrays(numBands: 3, sqrtSamples: 10)
        XCTAssertEqual(100, storage.numSamples)
        let sh = SphericalHarmonics(storage)
        var i = 0
        while !sh.isInit {
            sh.initNextSphericalSample()
            i += 1
        }
        XCTAssertEqual(100, i)
        sh.projectPolarFn(colorFromPolarCoordinates)
        
        // irradiance is the integral in the hemisphere, so a brighter value
        checkIrradiance(sh, color: simd_float3(-0.2, 1.05, 0.85), irradiance: simd_float3(1.46, 2.37, 2.41), normal: simd_float3(0, 1, 0))
        checkIrradiance(sh, color: simd_float3(-0.23, 1.0, 0.07), irradiance: simd_float3(1.43, 2.46, 0.85), normal: simd_float3(0, -1, 0))
        checkIrradiance(sh, color: simd_float3(1.14, 0.05, -0.04), irradiance: simd_float3(2.43, 1.18, 1.33), normal: simd_float3(1, 0, 0))
        checkIrradiance(sh, color: simd_float3(1, 1, 1), irradiance: simd_float3(2.48, 2.65, 1.9), normal: simd_float3(0, 0, -1))

    }
}


