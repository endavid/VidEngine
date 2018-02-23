//
//  ColorTests.swift
//  VidTestsTests
//
//  Created by David Gavilan on 2018/02/23.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import XCTest
import simd
import VidFramework
@testable import VidTests

class ColorTests: XCTestCase {
    let epsilon : Float = 0.0001

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
        XCTAssertEqual(1, rgba.a)
        XCTAssertLessThanOrEqual(fabs(rgba.r - 0.2), epsilon)
        XCTAssertLessThanOrEqual(fabs(rgba.g - 0.8), epsilon)
        XCTAssertLessThanOrEqual(fabs(rgba.b - 0.3), epsilon)
    }
    
    // https://en.wikipedia.org/wiki/Illuminant_D65
    func testD65() {
        let white = ReferenceWhite.D65
        let xyz = white.xyz
        XCTAssertTrue(IsClose(0.950456, xyz.x))
        XCTAssertTrue(IsClose(1, xyz.y))
        XCTAssertTrue(IsClose(1.08906, xyz.z))
    }
    
    func testsRGBToXYZ() {
        // XYZ to linear sRGB
        let m = RGBColorSpace.sRGB.toXYZ.inverse
        // matrix ref from http://www.brucelindbloom.com
        XCTAssertTrue(float3(3.2406, -0.9689, 0.0557).isClose(m[0]))
        XCTAssertTrue(float3(-1.5372, 1.8758, -0.2040).isClose(m[1]))
        XCTAssertTrue(float3(-0.4986, 0.0415, 1.0570).isClose(m[2]))
    }
}
