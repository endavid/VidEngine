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
    let origin = float3(0, 0, 0)
    
    func testRayTriangleMidIntersection() {
        let t = testTriangle
        let o = origin
        let ray1 = Ray(start: o, direction: float3(0,0,-1))
        let i1 = ray1.intersects(triangle: t)
        XCTAssertNotNil(i1)
        let p1 = ray1.travelDistance(d: i1!)
        XCTAssert(IsClose(0, length(p1 - float3(0,0,-1))))
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
        let p1 = ray1.travelDistance(d: i1!)
        let p2 = ray2.travelDistance(d: i2!)
        let p3 = ray3.travelDistance(d: i3!)
        XCTAssert(IsClose(0, length(p1 - t.a)))
        XCTAssert(IsClose(0, length(p2 - t.b)))
        XCTAssert(IsClose(0, length(p3 - t.c)))
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
        let p = ray.travelDistance(d: i!)
        XCTAssert(IsClose(0, length(p - pt)))
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
}
