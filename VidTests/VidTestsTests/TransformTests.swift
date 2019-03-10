//
//  TransformTests.swift
//  VidTestsTests
//
//  Created by David Gavilan on 2019/02/12.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import XCTest
import simd
import VidFramework
@testable import VidTests

func assertVectorRotation(angleAxis: AngleAxis, vector: float3, expected: float3) {
    let q = Quaternion(angleAxis)
    let qi = q.inverse()
    let v4 = float4(vector.x, vector.y, vector.z, 0)
    let e4 = float4(expected.x, expected.y, expected.z, 0)
    assertAlmostEqual(expected, q * vector)
    assertAlmostEqual(e4, q.toMatrix4() * v4)
    assertAlmostEqual(vector, qi * expected)
    assertAlmostEqual(v4, qi.toMatrix4() * e4)
}

class TransformTests: XCTestCase {
    let epsilon : Float = 0.0001
    let testTransform = Transform(position: float3(-1, 2, 0.5), scale: float3(1, 1, 1), rotation: Quaternion(AngleAxis(angle: .pi / 4, axis: float3(0,1,0))))
    
    func testVectorRotation() {
        let sq2 = sqrtf(2) / 2
        assertVectorRotation(
            angleAxis: AngleAxis(angle: .pi/4, axis: float3(0,1,0)),
            vector: float3(1, 0, 0),
            expected: float3(sq2,0,-sq2))
        assertVectorRotation(
            angleAxis: AngleAxis(angle: .pi/4, axis: float3(1,0,0)),
            vector: float3(0, 1, 0),
            expected: float3(0, sq2, sq2))
        assertVectorRotation(
            angleAxis: AngleAxis(angle: .pi/4, axis: float3(0,0,-1)),
            vector: float3(0, 1, 0),
            expected: float3(sq2, sq2, 0))
    }
    
    func testMatrixToTransform() {
        let t0 = Transform(
            position: float3(-1, 2, 0.5),
            scale: float3(1, 1, 1),
            rotation: Quaternion(AngleAxis(angle: .pi / 4, axis: float3(0,1,0))))
        let m = t0.toMatrix4()
        let t1 = Transform(matrix: m)
        assertAlmostEqual(t0.position, t1.position)
        assertAlmostEqual(t0.scale, t1.scale)
        assertAlmostEqual(t0.rotation.q, t1.rotation.q)
    }
    
    func testTransformVector() {
        let p0 = float3(7, 12, -3)
        let p = testTransform * p0
        assertAlmostEqual(float3(1.82843, 14.0, -6.57107), p, epsilon: epsilon)
    }

    func testInverseTransformVector() {
        let p0 = float3(7, 12, -3)
        let p1 = testTransform * p0
        let p2 = testTransform.inverse() * p1
        assertAlmostEqual(p0, p2, epsilon: epsilon)
        let m = testTransform.inverse().toMatrix4()
        XCTAssertLessThanOrEqual(abs(m[3,3]-1), epsilon)
        let p2w = m * float4(p1.x, p1.y, p1.z, 1.0)
        assertAlmostEqual(p0, p2w.xyz, epsilon: epsilon)
    }
    
    func testInverseCheckIdentity() {
        let t = Transform(position: float3(-0.2,0,-1), scale: float3(1,1,1), rotation: Quaternion(AngleAxis(angle: -.pi / 4, axis: float3(0,1,0))))
        let ti = t.inverse()
        let i1 = ti * t
        let identity = Transform()
        assertAlmostEqual(identity, i1)
        let i2 = t * ti
        assertAlmostEqual(identity, i2)
    }
}
