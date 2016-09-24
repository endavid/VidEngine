//
//  VidEngineTests.swift
//
//  Created by David Gavilan on 3/31/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import XCTest
import simd
@testable import VidEngine

class VidEngineTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
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
        unsafe.deallocate(capacity: 2)
    }
    
    func testMatrix4() {
        var m = Matrix4()
        XCTAssertEqual(0, m[3,3])
        XCTAssertEqual(4 * 4 * 4, MemoryLayout<Matrix4>.size)
        // [column, row], so this sets the translation
        m[3,0] = 1
        m[3,1] = 3
        m[3,2] = 9
        let unsafe = UnsafeMutablePointer<Float>.allocate(capacity: 4 * 4)
        memcpy(unsafe, &m, MemoryLayout<Matrix4>.size)
        // check that indeed the data is stored in column-major order
        XCTAssertEqual(1, unsafe[12])
        XCTAssertEqual(3, unsafe[13])
        XCTAssertEqual(9, unsafe[14])
        unsafe.deallocate(capacity: 4 * 4)
    }
    
    func testSpherical() {
        let sph = Spherical(v: float3(0,1,0))
        XCTAssertEqual(sph.r, 1)
        XCTAssertEqual(sph.θ, 0)
        XCTAssertEqual(sph.φ, 0)
    }
    
    func testSpectrum() {
        let spectrum = Spectrum(data: [400: 0.343, 404: 0.445, 408: 0.551, 412: 0.624])
        let m1 = spectrum.getIntensity(404)
        let m2 = spectrum.getIntensity(405)
        XCTAssertEqual(0.445, m1)
        XCTAssertEqual(0.471500009, m2)
    }
    
    func testXYZtoRGB() {
        // http://www.brucelindbloom.com
        // Model: sRGB, Gamma: 1.0
        let xyz = CieXYZ(xyz: float3(0.422683, 0.636309, 0.384312))
        let rgba = xyz.toRGBA()
        let epsilon : Float = 0.0001
        XCTAssertEqual(1, rgba.a)
        XCTAssertLessThanOrEqual(fabs(rgba.r - 0.2), epsilon)
        XCTAssertLessThanOrEqual(fabs(rgba.g - 0.8), epsilon)
        XCTAssertLessThanOrEqual(fabs(rgba.b - 0.3), epsilon)
    }
    
}
