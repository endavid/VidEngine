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

func assertVectorRotation(angleAxis: AngleAxis, vector: simd_float3, expected: simd_float3) {
    let q = Quaternion(angleAxis)
    let qi = q.inverse()
    let v4 = simd_float4(vector.x, vector.y, vector.z, 0)
    let e4 = simd_float4(expected.x, expected.y, expected.z, 0)
    assertAlmostEqual(expected, q * vector)
    assertAlmostEqual(e4, q.toMatrix4() * v4)
    assertAlmostEqual(vector, qi * expected)
    assertAlmostEqual(v4, qi.toMatrix4() * e4)
    let qm = Quaternion(q.toMatrix3())
    assertAlmostEqual(q.q, qm.q)
}

class TransformTests: XCTestCase {
    let epsilon : Float = 0.0001
    let testTransform = Transform(position: simd_float3(-1, 2, 0.5), scale: simd_float3(1, 1, 1), rotation: Quaternion(AngleAxis(angle: .pi / 4, axis: simd_float3(0,1,0))))
    
    func testVectorRotation() {
        let sq2 = sqrtf(2) / 2
        assertVectorRotation(
            angleAxis: AngleAxis(angle: .pi/4, axis: simd_float3(0,1,0)),
            vector: simd_float3(1, 0, 0),
            expected: simd_float3(sq2,0,-sq2))
        assertVectorRotation(
            angleAxis: AngleAxis(angle: .pi/4, axis: simd_float3(1,0,0)),
            vector: simd_float3(0, 1, 0),
            expected: simd_float3(0, sq2, sq2))
        assertVectorRotation(
            angleAxis: AngleAxis(angle: .pi/4, axis: simd_float3(0,0,-1)),
            vector: simd_float3(0, 1, 0),
            expected: simd_float3(sq2, sq2, 0))
    }
    
    func testQuaternionFromMatrix() {
        let q = Quaternion(w: 0.9603172, v: simd_float3(0.00787969, -0.2787481, -0.005322565))
        let m = q.toMatrix3()
        let qm = Quaternion(m)
        assertAlmostEqual(q.q, qm.q)
        let v = simd_float3(9.75, -0.98, 3.175)
        assertAlmostEqual(m * v, q * v, epsilon: 1e-5)
    }
    
    func testMatrixToTransform() {
        let t0 = Transform(
            position: simd_float3(-1, 2, 0.5),
            scale: simd_float3(1, 1, 1),
            rotation: Quaternion(AngleAxis(angle: .pi / 4, axis: simd_float3(0,1,0))))
        let m = t0.toMatrix4()
        let t1 = Transform(rotationAndTranslation: m)
        assertAlmostEqual(t0.position, t1.position)
        assertAlmostEqual(t0.scale, t1.scale)
        assertAlmostEqual(t0.rotation.q, t1.rotation.q)
    }
    
    func testTransformVector() {
        let p0 = simd_float3(7, 12, -3)
        let p = testTransform * p0
        assertAlmostEqual(simd_float3(1.82843, 14.0, -6.57107), p, epsilon: epsilon)
    }

    func testInverseTransformVector() {
        let p0 = simd_float3(7, 12, -3)
        let p1 = testTransform * p0
        let inv = try? testTransform.inverse()
        XCTAssertNotNil(inv)
        if let inv = inv {
            let p2 = inv * p1
            assertAlmostEqual(p0, p2, epsilon: epsilon)
            let m = inv.toMatrix4()
            XCTAssertLessThanOrEqual(abs(m[3,3]-1), epsilon)
            let p2w = m * simd_float4(p1.x, p1.y, p1.z, 1.0)
            assertAlmostEqual(p0, p2w.xyz, epsilon: epsilon)
        }
    }
    
    func testInverseCheckIdentity() {
        let t = Transform(position: simd_float3(-0.2,0,-1), scale: simd_float3(1,1,1), rotation: Quaternion(AngleAxis(angle: -.pi / 4, axis: simd_float3(0,1,0))))
        let ti = try? t.inverse()
        XCTAssertNotNil(ti)
        if let ti = ti {
            let i1 = ti * t
            let identity = Transform()
            assertAlmostEqual(identity, i1)
            let i2 = t * ti
            assertAlmostEqual(identity, i2)
        }
    }
    
    func testRotationInverse() {
        let t = Transform(position: simd_float3(-1, 0, -2), scale: simd_float3(2, 2, 2), rotation: Quaternion(AngleAxis(angle: .pi/2, axis: simd_float3(0,1,0))))
        let d = simd_float3(0, 0, -1)
        let it = try? t.inverse()
        XCTAssertNotNil(it)
        if let it = it {
            let inverseDirection = it.rotate(direction: d)
            let matrixInverse = t.toMatrix4().inverse
            let id0 = matrixInverse * simd_float4(d.x, d.y, d.z, 0)
            let inverseDirectionFromMatrix = normalize(id0.xyz)
            assertAlmostEqual(simd_float3(1, 0, 0), inverseDirection)
            assertAlmostEqual(inverseDirectionFromMatrix, inverseDirection)
        }
    }
    
    func testRotationInverseMatrix() {
        let q = Quaternion(w: 0.9603172, v: simd_float3(0.00787969, -0.2787481, -0.005322565))
        let m = q.toMatrix3()
        // if the matrix is orthonormal, the transpose == inverse
        assertAlmostEqual(m.inverse, m.transpose)
    }
    
    func testArbitraryTransform() {
        let transform = Transform(position: simd_float3(0.2833359, -0.49168962, -0.65075946), scale: simd_float3(0.6749687, 1.0, 1.3709693), rotation: Quaternion(w: 0.9603172, v: simd_float3(0.00787969, -0.2787481, -0.005322565)))
        let point = simd_float4(-0.012088692, -0.037747566, -0.039436463, 1)
        let m = transform.toMatrix4()
        let tm = Transform(transform: m)
        assertAlmostEqual(transform.position, tm.position)
        assertAlmostEqual(transform.scale, tm.scale)
        assertAlmostEqual(transform.rotation.q, transform.rotation.q)
        assertAlmostEqual((m * point).xyz, transform * point.xyz)
        let identity = float4x4.identity
        let mi = m.inverse
        assertAlmostEqual(identity, m * mi)
        XCTAssertThrowsError(try transform.inverse()) {(error) in
            XCTAssertTrue(error is MathError)
            if let error = error as? MathError {
                switch(error) {
                case .unsupported(let msg):
                    XCTAssertEqual(msg, "Transforms with anisotropic scaling can't be inverted")
                }
            }
        }
        //let ti = transform.inverse()
        //let tim =  ti.toMatrix4()
        //assertAlmostEqual(identity, m * tim)
        //assertAlmostEqual(mi, tim)
        //assertAlmostEqual((mi * point).xyz, ti * point.xyz)
    }
    
    func testArbitraryTransformUniformScaling() {
        let transform = Transform(position: simd_float3(0.2833359, -0.49168962, -0.65075946), scale: simd_float3(0.7, 0.7, 0.7), rotation: Quaternion(w: 0.9603172, v: simd_float3(0.00787969, -0.2787481, -0.005322565)))
        let point = simd_float4(-0.012088692, -0.037747566, -0.039436463, 1)
        let m = transform.toMatrix4()
        let tm = Transform(transform: m)
        assertAlmostEqual(transform.position, tm.position)
        assertAlmostEqual(transform.scale, tm.scale)
        assertAlmostEqual(transform.rotation.q, transform.rotation.q)
        assertAlmostEqual((m * point).xyz, transform * point.xyz)
        let identity = float4x4.identity
        let mi = m.inverse
        assertAlmostEqual(identity, m * mi)
        let ti = try? transform.inverse()
        XCTAssertNotNil(ti)
        if let ti = ti {
            let tim =  ti.toMatrix4()
            assertAlmostEqual(identity, m * tim)
            assertAlmostEqual(mi, tim)
            assertAlmostEqual((mi * point).xyz, ti * point.xyz)
        }
    }
}
