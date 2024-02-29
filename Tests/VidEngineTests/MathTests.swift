//
//  MathTests.swift
//  VidTestsTests
//
//  Created by David Gavilan on 2019/03/23.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import XCTest
import simd
@testable import VidEngine

class MathTests: XCTestCase {
    func testSVDMatrix3() {
        let m = float3x3(
            simd_float3(1, 3, 9),
            simd_float3(-3, 8, 7),
            simd_float3(0.5, -0.1, -3))
        let (u, s, v) = svd(matrix: m)
        let reconstructed = u * float3x3(diagonal: s) * v.inverse
        assertAlmostEqual(m, reconstructed)
        // matrix values obtained with Octave for comparison
        // m = [1 3 9; -3 8 7; 0.5 -0.1 -3]'
        // [u, s, v] = svd(m)
        assertAlmostEqual(simd_float3(14.086166, 4.759304, 1.0903881), s)
        let octaveU = float3x3(rows: [
            simd_float3(0.12164, 0.53498, -0.83606),
            simd_float3(-0.56327, -0.65635, -0.50194),
            simd_float3(-0.81727, 0.53198, 0.22150)
        ])
        let octaveV = float3x3(rows: [
            simd_float3(-0.633501, 0.704683, -0.319529),
            simd_float3(-0.751941, -0.658041, 0.039576),
            simd_float3(0.182375, -0.265338, -0.946750)
        ])
        assertAlmostEqual(octaveU, u, epsilon: 1e-5)
        assertAlmostEqual(octaveV, v, epsilon: 1e-5)
    }
    func testLine() {
        let a = simd_float4(0, 1, -1, 2)
        let b = simd_float4(1, -1, 10, -3)
        let line = Line(start: a, end: b)
        assertAlmostEqual(a, line.start, epsilon: 1e-20)
        assertAlmostEqual(b, line.end, epsilon: 1e-20)
    }
}

