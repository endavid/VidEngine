//
//  TestHelpers.swift
//  VidTestsTests
//
//  Created by David Gavilan on 2019/02/13.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import XCTest
import simd
import VidFramework

func assertAlmostEqual(_ expected: float3, _ actual: float3, epsilon: Float = 1e-6) {
    let d = distance(expected, actual)
    if d > epsilon {
        NSLog("expected: \(expected); actual: \(actual)")
    }
    XCTAssertLessThanOrEqual(d, epsilon)
}
func assertAlmostEqual(_ expected: float4, _ actual: float4, epsilon: Float = 1e-6) {
    let d = distance(expected, actual)
    if d > epsilon {
        NSLog("expected: \(expected); actual: \(actual)")
    }
    XCTAssertLessThanOrEqual(d, epsilon)
}
func assertAlmostEqual(_ expected: float4x4, _ actual: float4x4, epsilon: Float = 1e-6) {
    let (ex, ey, ez, ew) = expected.columns
    let (ax, ay, az, aw) = actual.columns
    assertAlmostEqual(ex, ax, epsilon: epsilon)
    assertAlmostEqual(ey, ay, epsilon: epsilon)
    assertAlmostEqual(ez, az, epsilon: epsilon)
    assertAlmostEqual(ew, aw, epsilon: epsilon)
}
func assertAlmostEqual(_ expected: Transform, _ actual: Transform, epsilon: Float = 1e-6) {
    assertAlmostEqual(expected.position, actual.position, epsilon: epsilon)
    assertAlmostEqual(expected.scale, actual.scale, epsilon: epsilon)
    assertAlmostEqual(expected.rotation.q, actual.rotation.q, epsilon: epsilon)
}
