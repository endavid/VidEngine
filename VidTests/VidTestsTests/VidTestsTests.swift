//
//  VidTestsTests.swift
//  VidTestsTests
//
//  Created by David Gavilan on 2018/02/19.
//  Copyright © 2018 David Gavilan. All rights reserved.
//
//

/*
 Troubleshooting
 ---------------
VidTests.app encountered an error (Failed to establish communication with the test runner. (Underlying error: Unable to connect to test manager on 7e59a77b00b93c4d868e5dd675d97fee0024ec9e. (Underlying error: kAMDInvalidServiceError: The service is invalid.)))
 
 This seems to happen when trying to run the tests wirelessly,
 on iPhoneX at least. Plugging the device using a USB cable seems
 to fix the issue.
*/


import XCTest
import simd
import VidFramework
@testable import VidTests

class VidTestsTests: XCTestCase {
    let epsilon : Float = 0.0001

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testVector2() {
        var v = float2(0, 3)
        XCTAssertEqual(0, v.x)
        XCTAssertEqual(3, v.y)
        XCTAssertEqual(4 * 2, MemoryLayout<float2>.size)
        let unsafe = UnsafeMutablePointer<Float>.allocate(capacity: 2)
        memcpy(unsafe, &v, MemoryLayout<float2>.size)
        XCTAssertEqual(0, unsafe[0])
        XCTAssertEqual(3, unsafe[1])
        unsafe.deallocate()
    }
    
    func testSpherical() {
        let sph = Spherical(v: float3(0,1,0))
        XCTAssertEqual(sph.r, 1)
        XCTAssertEqual(sph.θ, 0)
        XCTAssertEqual(sph.φ, 0)
    }
        
    func testTransform() {
        let p0 = float3(7, 12, -3)
        let t = Transform(position: float3(-1, 2, 0.5), scale: float3(1, 1, 1), rotation: Quaternion(AngleAxis(angle: .pi / 4, axis: float3(0,1,0))))
        let p1 = t * p0
        XCTAssertLessThanOrEqual(distance(p1, float3(1.82843, 14.0, -6.57107)), epsilon)
        let p2 = t.inverse() * p1
        XCTAssertLessThanOrEqual(distance(p2, p0), epsilon)
        let m = t.inverse().toMatrix4()
        XCTAssertLessThanOrEqual(abs(m[3,3]-1), epsilon)
        let p2w = m * float4(p1.x, p1.y, p1.z, 1.0)
        print(p2w)
        XCTAssertLessThanOrEqual(distance(p2w, float4(p0.x, p0.y, p0.z, 1.0)), epsilon)
    }
    
    func testCameraProjection() {
        let camera = Camera()
        camera.setPerspectiveProjection(fov: 90, near: 0.1, far: 100, aspectRatio: 1)
        camera.setViewDirection(float3(0,0,-1), up: float3(0,1,0))
        camera.setEyePosition(float3(0,2,20))
        assertAlmostEqual(float4x4([
                float4(1,0,0,0),
                float4(0,1,0,0),
                float4(0,0,-1.002,-1.0),
                float4(0,0,-0.2002,0)
            ]),
            camera.projection, epsilon: epsilon)
        assertAlmostEqual(float4x4([
                float4(1,0,0,0),
                float4(0,1,0,0),
                float4(0,0,0,-4.995),
                float4(0,0,-1,5.005)
            ]),
            camera.projectionInverse, epsilon: epsilon)
        assertAlmostEqual(Transform(
                position: float3(0, 2, 20),
                scale: float3(1, 1, 1),
                rotation: Quaternion(w: 1, v: float3(0,0,0))
            ),
            camera.transform, epsilon: epsilon)
        let worldPoint = float3(0.6, 1.2, -5)
        var viewPoint = camera.viewTransform * worldPoint
        // checked with Octave
        assertAlmostEqual(float3(0.6, -0.8, -25.0), viewPoint, epsilon: epsilon)
        var worldPoint4 = float4(worldPoint.x, worldPoint.y, worldPoint.z, 1.0)
        var viewPoint4 = camera.viewMatrix * worldPoint4
        assertAlmostEqual(float4(0.6, -0.8, -25.0, 1.0), viewPoint4, epsilon: epsilon)
        let screenPoint = camera.projection * viewPoint4
        assertAlmostEqual(float4(0.6, -0.8, 24.84980, 25.0), screenPoint, epsilon: epsilon)
        var p = screenPoint * (1.0 / screenPoint.w)
        p = camera.projectionInverse * p
        p = p * (1.0 / p.w)
        assertAlmostEqual(p, viewPoint4, epsilon: epsilon)
        let wp = camera.transform * float3(p.x, p.y, p.z)
        assertAlmostEqual(wp, worldPoint, epsilon: epsilon)
        let qx = Quaternion(AngleAxis(angle: .pi / 4, axis: float3(0,1,0)))
        camera.rotation = qx
        viewPoint = camera.viewTransform * worldPoint
        assertAlmostEqual(float3(18.1019, -0.8, -17.2534), viewPoint, epsilon: epsilon)
        worldPoint4 = float4(worldPoint.x, worldPoint.y, worldPoint.z, 1.0)
        viewPoint4 = camera.viewMatrix * worldPoint4
        assertAlmostEqual(float4(18.1019, -0.8, -17.2534, 1.0), viewPoint4, epsilon: epsilon)
    }
    
    // average: 0.027 secs
    func testBaselinePerformance() {
        self.measure {
            let count = 2048 * 2048
            var v : Float = 0
            for i in 0..<count {
                v = Float(i)
            }
            v += 1
        }
    }
    // average: 0.461 seconds (iPhone6 iOS 10.2) ~5.8 times slower than native arrays
    func testArrayPerformance() {
        self.measure {
            var array = [Float](repeating: 1, count: 2048 * 2048)
            for i in 0..<array.count {
                array[(i+1)%array.count] = Float(i)
            }
        }
    }
    
    // average: 0.079 seconds
    func testNativeArrayPerformance() {
        self.measure {
            let count = 2048 * 2048
            let array = UnsafeMutablePointer<Float>.allocate(capacity: count)
            for i in 0..<count {
                array[(i+1)%count] = Float(i)
            }
            array.deallocate()
        }
    }

    
}
