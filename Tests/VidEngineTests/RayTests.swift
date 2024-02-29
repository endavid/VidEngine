//
//  RayTests.swift
//  VidTestsTests
//
//  Created by David Gavilan on 2019/03/10.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import XCTest
import simd
@testable import VidEngine

class RayTests: XCTestCase {
    let testTriangle = Triangle(a: simd_float3(-2,0,-1), b: simd_float3(2, 0, -1), c: simd_float3(0,2,-1))
    let testCenteredTriangle = Triangle(a: simd_float3(-2,0,0), b: simd_float3(2, 0, 0), c: simd_float3(0,2,0))
    let origin = simd_float3(0, 0, 0)
    let testTwist = Transform(position: simd_float3(0,0,0), scale: simd_float3(1,1,1), rotation: Quaternion(AngleAxis(angle: .pi / 2, axis: simd_float3(0,0,1))))
    let testYrotation = Transform(position: simd_float3(-0.2,0,-1), scale: simd_float3(1,1,1), rotation: Quaternion(AngleAxis(angle: -.pi / 4, axis: simd_float3(0,1,0))))
    let testRay = Ray(start: simd_float3(-0.012088692, -0.037747566, -0.039436463), direction: simd_float3(0.19631016, -0.78230625, -0.5911508))
    let testTransform = Transform(position: simd_float3(0.2833359, -0.49168962, -0.65075946), scale: simd_float3(0.6749687, 1.0, 1.3709693), rotation: Quaternion(w: 0.9603172, v: simd_float3(0.00787969, -0.2787481, -0.005322565)))
    
    func testRayTriangleMidIntersection() {
        let t = testTriangle
        let o = origin
        let ray1 = Ray(start: o, direction: simd_float3(0,0,-1))
        let i1 = ray1.intersects(triangle: t)
        XCTAssertNotNil(i1)
        if let i1 = i1 {
            let p1 = ray1.travelDistance(d: i1)
            assertAlmostEqual(simd_float3(0,0,-1), p1)
        }
        // opposite direction
        let ray2 = Ray(start: o, direction: simd_float3(0,0,1))
        let i2 = ray2.intersects(triangle: t)
        XCTAssertNil(i2)
    }
    func testRayTriangleVertexIntersection() {
        let t = testTriangle
        let o = origin
        // check that the intersection with the vertices work
        let ray1 = Ray(start: o, direction: normalize(t.a - o))
        let ray2 = Ray(start: o, direction: normalize(t.b - o))
        let ray3 = Ray(start: o, direction: normalize(t.c - o))
        let i1 = ray1.intersects(triangle: t)
        let i2 = ray2.intersects(triangle: t)
        let i3 = ray3.intersects(triangle: t)
        XCTAssertNotNil(i1)
        XCTAssertNotNil(i2)
        XCTAssertNotNil(i3)
        if let i1 = i1, let i2 = i2, let i3 = i3 {
            let p1 = ray1.travelDistance(d: i1)
            let p2 = ray2.travelDistance(d: i2)
            let p3 = ray3.travelDistance(d: i3)
            assertAlmostEqual(t.a, p1)
            assertAlmostEqual(t.b, p2)
            assertAlmostEqual(t.c, p3)
        }
    }
    func testParallelRayTriangleIntersection() {
        let t = testTriangle
        // parallel to the triangle
        let ray = Ray(start: simd_float3(1,1,-0.99), direction: simd_float3(0,1,0))
        let i = ray.intersects(triangle: t)
        XCTAssertNil(i)
    }
    func testRayTriangleArbitraryIntersection() {
        let t = testTriangle
        let o = origin
        // point in the triangle
        let pt = simd_float3(1, 1, -1)
        let ray = Ray(start: o, direction: normalize(pt - o))
        let i = ray.intersects(triangle: t)
        XCTAssertNotNil(i)
        if let i = i {
            let p = ray.travelDistance(d: i)
            assertAlmostEqual(pt, p)
        }
    }
    func testRayTriangleClosePointIntersection() {
        let t = testTriangle
        let o = origin
        // point a bit off
        let off = simd_float3(-0.1,0,0) + t.a
        let ray = Ray(start: o, direction: normalize(off - o))
        let i = ray.intersects(triangle: t)
        XCTAssertNil(i)
    }
    func testRayTwistedTriangleIntersection() {
        let t = testTwist * testTriangle
        let ray = Ray(start: origin, direction: simd_float3(0,0,-1))
        let i = ray.intersects(triangle: t)
        XCTAssertNotNil(i)
        if let i = i {
            let p = ray.travelDistance(d: i)
            assertAlmostEqual(simd_float3(0,0,-1), p)
        }
    }
    func testTwistedRayTriangleIntersection() {
        let ray = Ray(start: origin, direction: simd_float3(0,0,-1))
        let inv = try? testTwist.inverse()
        XCTAssertNotNil(inv)
        if let inv = inv {
            let rotatedRay = inv * ray
            let i = rotatedRay.intersects(triangle: testTriangle)
            XCTAssertNotNil(i)
            if let i = i {
                let p1 = rotatedRay.travelDistance(d: i)
                assertAlmostEqual(simd_float3(0,0,-1), p1)
                let p2 = ray.travelDistance(d: i)
                assertAlmostEqual(simd_float3(0,0,-1), p2)
            }
        }
    }
    func testRayYRotatedTriangleIntersection() {
        let t = testYrotation * testCenteredTriangle
        let ray = Ray(start: origin, direction: simd_float3(0,0,-1))
        let i = ray.intersects(triangle: t)
        XCTAssertNotNil(i)
        if let i = i {
            let p = ray.travelDistance(d: i)
            // after rotating and translating slightly to the left,
            // we should intersect a point closer than the original
            // triangle distance of 1m
            assertAlmostEqual(simd_float3(0,0,-0.8), p)
        }
    }
    func testYRotatedRayTriangleIntersection() {
        let ray = Ray(start: origin, direction: simd_float3(0,0,-1))
        let inv = try? testYrotation.inverse()
        XCTAssertNotNil(inv)
        if let inv = inv {
            let rotatedRay = inv * ray
            let i = rotatedRay.intersects(triangle: testCenteredTriangle)
            XCTAssertNotNil(i)
            if let i = i {
                let p1 = rotatedRay.travelDistance(d: i)
                assertAlmostEqual(simd_float3(0.28284281,0,0), p1)
                let p2 = ray.travelDistance(d: i)
                assertAlmostEqual(simd_float3(0,0,-0.8), p2)
            }
        }
    }
    func testRayTranslatedTriangleIntersection() {
        let transform = Transform(position: simd_float3(0.01, -0.01, -5))
        let t = transform * testTriangle
        let ray = Ray(start: origin, direction: simd_float3(0,0,-1))
        let i = ray.intersects(triangle: t)
        XCTAssertNotNil(i)
        if let i = i {
            let p = ray.travelDistance(d: i)
            assertAlmostEqual(simd_float3(0,0,-6), p)
        }
    }
    func testTranslatedRayTriangleIntersection() {
        let transform = Transform(position: simd_float3(0.01, -0.01, -5))
        let ray = Ray(start: origin, direction: simd_float3(0,0,-1))
        let inv = try? transform.inverse()
        XCTAssertNotNil(inv)
        if let inv = inv {
            let tray = inv * ray
            let i = tray.intersects(triangle: testTriangle)
            XCTAssertNotNil(i)
            if let i = i {
                let p1 = tray.travelDistance(d: i)
                assertAlmostEqual(simd_float3(-0.01, 0.01, -1), p1)
                let p2 = ray.travelDistance(d: i)
                assertAlmostEqual(simd_float3(0,0,-6), p2)
            }
        }
    }
    func testRayScaledTriangleIntersection() {
        var transform = testYrotation
        transform.scale = simd_float3(2, 10, 2)
        let t = transform * testCenteredTriangle
        let ray = Ray(start: origin, direction: normalize(simd_float3(0, 8, -1)))
        let i = ray.intersects(triangle: t)
        XCTAssertNotNil(i)
        if let i = i {
            let p = ray.travelDistance(d: i)
            assertAlmostEqual(simd_float3(0, 6.4, -0.8), p)
            XCTAssert(IsClose(i, 6.44980621))
        }
    }
    
    func testRayInverse() {
        let t = Transform(position: simd_float3(-1, 0, -2), scale: simd_float3(2, 1, 2), rotation: Quaternion(AngleAxis(angle: .pi/2, axis: simd_float3(0,1,0))))
        let p = t * simd_float3(0.5, 0, 0)
        assertAlmostEqual(simd_float3(-1,0,-3), p)
        let ray = Ray(start: origin, direction: simd_float3(0, 0, -1))
        let m = t.toMatrix4()
        let ir = m.inverse * ray
        assertAlmostEqual(simd_float3(-1, 0, 0.5), ir.start)
        assertAlmostEqual(simd_float3(1, 0, 0), ir.direction)
    }
    
    func testScaledRayTriangleIntersection() {
        var transform = testYrotation
        transform.scale = simd_float3(2, 10, 2)
        let ray = Ray(start: origin, direction: normalize(simd_float3(0, 8, -1)))
        let m = transform.toMatrix4()
        let sray = m.inverse * ray
        let i = sray.intersects(triangle: testCenteredTriangle)
        XCTAssertNotNil(i)
        if let i = i {
            let p1 = sray.travelDistance(d: i)
            assertAlmostEqual(simd_float3(0.14142138, 0.64, 0.0), p1)
            XCTAssert(IsClose(i, 0.754718482))
            // note that the distance is scaled! we can't use it
            // to traverse the original ray
            let p2 = transform * p1
            assertAlmostEqual(simd_float3(0, 6.4, -0.8), p2)
        }
    }
    func testArbitraryRayRotation() {
        let ray = testRay
        let transform = testTransform
        let modelRay = transform.toMatrix4().inverse * ray
        let r = transform * modelRay
        assertAlmostEqual(ray.start, r.start)
        assertAlmostEqual(ray.direction, r.direction)
    }
    func testArbitraryRealExample() {
        let ray = testRay
        let transform = testTransform
        let triangle = Triangle(a: simd_float3(-0.5, 0.0, 0.5), b: simd_float3(0.5, 0.0, 0.5), c: simd_float3(0.5, 0.0, -0.5))
        // let's check intersection in model space first
        let modelRay = transform.toMatrix4().inverse * ray
        let d = modelRay.intersects(triangle: triangle)
        XCTAssertNotNil(d)
        // now let's check in world space
        let worldTriangle = transform * triangle
        let dw = ray.intersects(triangle: worldTriangle)
        XCTAssertNotNil(dw)
        if let d = d, let dw = dw {
            let modelPoint = modelRay.travelDistance(d: d)
            let point = transform * modelPoint
            let worldPoint = ray.travelDistance(d: dw)
            assertAlmostEqual(worldPoint, point)
        }
    }
}
