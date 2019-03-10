//
//  RayTests.swift
//  VidTestsTests
//
//  Created by David Gavilan on 2019/03/10.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import XCTest
import simd
import VidFramework
@testable import VidTests

class RayTests: XCTestCase {
    let testTriangle = Triangle(a: float3(-2,0,-1), b: float3(2, 0, -1), c: float3(0,2,-1))
    let testCenteredTriangle = Triangle(a: float3(-2,0,0), b: float3(2, 0, 0), c: float3(0,2,0))
    let origin = float3(0, 0, 0)
    let testTwist = Transform(position: float3(0,0,0), scale: float3(1,1,1), rotation: Quaternion(AngleAxis(angle: .pi / 2, axis: float3(0,0,1))))
    let testYrotation = Transform(position: float3(-0.2,0,-1), scale: float3(1,1,1), rotation: Quaternion(AngleAxis(angle: -.pi / 4, axis: float3(0,1,0))))
    
    func testRayTriangleMidIntersection() {
        let t = testTriangle
        let o = origin
        let ray1 = Ray(start: o, direction: float3(0,0,-1))
        let i1 = ray1.intersects(triangle: t)
        XCTAssertNotNil(i1)
        if let i1 = i1 {
            let p1 = ray1.travelDistance(d: i1)
            assertAlmostEqual(float3(0,0,-1), p1)
        }
        // opposite direction
        let ray2 = Ray(start: o, direction: float3(0,0,1))
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
        let ray = Ray(start: float3(1,1,-0.99), direction: float3(0,1,0))
        let i = ray.intersects(triangle: t)
        XCTAssertNil(i)
    }
    func testRayTriangleArbitraryIntersection() {
        let t = testTriangle
        let o = origin
        // point in the triangle
        let pt = float3(1, 1, -1)
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
        let off = float3(-0.1,0,0) + t.a
        let ray = Ray(start: o, direction: normalize(off - o))
        let i = ray.intersects(triangle: t)
        XCTAssertNil(i)
    }
    func testRayTwistedTriangleIntersection() {
        let t = testTwist * testTriangle
        let ray = Ray(start: origin, direction: float3(0,0,-1))
        let i = ray.intersects(triangle: t)
        XCTAssertNotNil(i)
        if let i = i {
            let p = ray.travelDistance(d: i)
            assertAlmostEqual(float3(0,0,-1), p)
        }
    }
    func testTwistedRayTriangleIntersection() {
        let ray = Ray(start: origin, direction: float3(0,0,-1))
        let rotatedRay = testTwist.inverse() * ray
        let i = rotatedRay.intersects(triangle: testTriangle)
        XCTAssertNotNil(i)
        if let i = i {
            let p1 = rotatedRay.travelDistance(d: i)
            assertAlmostEqual(float3(0,0,-1), p1)
            let p2 = ray.travelDistance(d: i)
            assertAlmostEqual(float3(0,0,-1), p2)
        }
    }
    func testRayYRotatedTriangleIntersection() {
        let t = testYrotation * testCenteredTriangle
        let ray = Ray(start: origin, direction: float3(0,0,-1))
        let i = ray.intersects(triangle: t)
        XCTAssertNotNil(i)
        if let i = i {
            let p = ray.travelDistance(d: i)
            // after rotating and translating slightly to the left,
            // we should intersect a point closer than the original
            // triangle distance of 1m
            assertAlmostEqual(float3(0,0,-0.8), p)
        }
    }
    func testYRotatedRayTriangleIntersection() {
        let ray = Ray(start: origin, direction: float3(0,0,-1))
        let rotatedRay = testYrotation.inverse() * ray
        let i = rotatedRay.intersects(triangle: testCenteredTriangle)
        XCTAssertNotNil(i)
        if let i = i {
            let p1 = rotatedRay.travelDistance(d: i)
            assertAlmostEqual(float3(0.28284281,0,0), p1)
            let p2 = ray.travelDistance(d: i)
            assertAlmostEqual(float3(0,0,-0.8), p2)
        }
    }
    func testRayTranslatedTriangleIntersection() {
        let transform = Transform(position: float3(0.01, -0.01, -5))
        let t = transform * testTriangle
        let ray = Ray(start: origin, direction: float3(0,0,-1))
        let i = ray.intersects(triangle: t)
        XCTAssertNotNil(i)
        if let i = i {
            let p = ray.travelDistance(d: i)
            assertAlmostEqual(float3(0,0,-6), p)
        }
    }
    func testTranslatedRayTriangleIntersection() {
        let transform = Transform(position: float3(0.01, -0.01, -5))
        let ray = Ray(start: origin, direction: float3(0,0,-1))
        let tray = transform.inverse() * ray
        let i = tray.intersects(triangle: testTriangle)
        XCTAssertNotNil(i)
        if let i = i {
            let p1 = tray.travelDistance(d: i)
            assertAlmostEqual(float3(-0.01, 0.01, -1), p1)
            let p2 = ray.travelDistance(d: i)
            assertAlmostEqual(float3(0,0,-6), p2)
        }
    }
    func testRayScaledTriangleIntersection() {
        var transform = testYrotation
        transform.scale = float3(2, 10, 2)
        let t = transform * testCenteredTriangle
        let ray = Ray(start: origin, direction: normalize(float3(0, 8, -1)))
        let i = ray.intersects(triangle: t)
        XCTAssertNotNil(i)
        if let i = i {
            let p = ray.travelDistance(d: i)
            assertAlmostEqual(float3(0, 6.4, -0.8), p)
        }
    }
    func testScaledRayTriangleIntersection() {
        var transform = testYrotation
        transform.scale = float3(2, 10, 2)
        let ray = Ray(start: origin, direction: normalize(float3(0, 8, -1)))
        let sray = transform.inverse() * ray
        let i = sray.intersects(triangle: testCenteredTriangle)
        XCTAssertNotNil(i)
        if let i = i {
            let p1 = sray.travelDistance(d: i)
            assertAlmostEqual(float3(0, 6.4, -0.8), p1)
            let p2 = ray.travelDistance(d: i)
            assertAlmostEqual(float3(0, 6.4, -0.8), p2)
        }
    }
}
