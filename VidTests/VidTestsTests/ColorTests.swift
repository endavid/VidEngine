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
        let rgba = xyz.toRGBA(colorSpace: .sRGB)
        XCTAssertEqual(1, rgba.a)
        XCTAssertTrue(IsClose(0.2, rgba.r))
        XCTAssertTrue(IsClose(0.8, rgba.g))
        XCTAssertTrue(IsClose(0.3, rgba.b))
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
        let ref = float3x3([
            float3(3.2406, -0.9689, 0.0557),
            float3(-1.5372, 1.8758, -0.2040),
            float3(-0.4986, 0.0415, 1.0570)
            ])
        XCTAssertTrue(ref[0].isClose(m[0]))
        XCTAssertTrue(ref[1].isClose(m[1]))
        XCTAssertTrue(ref[2].isClose(m[2]))
        // check again with constant Y = 1
        let sRGB = RGBColorSpace(
            red: CiexyY(x: 0.6400, y: 0.3300),
            green: CiexyY(x: 0.3000, y: 0.6000),
            blue: CiexyY(x: 0.1500, y: 0.0600),
            white: .D65)
        let m1 = sRGB.toXYZ.inverse
        XCTAssertTrue(ref[0].isClose(m1[0]))
        XCTAssertTrue(ref[1].isClose(m1[1]))
        XCTAssertTrue(ref[2].isClose(m1[2]))
    }
    
    func testP3ToSrgb() {
        let m = RGBColorSpace.sRGB.toRGB * RGBColorSpace.dciP3.toXYZ
        print(m)
        let ref = float3x3([
            float3(1.22494, -0.0420569, -0.0196376),
            float3(-0.22494, 1.04206, -0.078636),
            float3(4.61524e-08, 1.34893e-08, 1.09827)
        ])
        XCTAssertTrue(ref[0].isClose(m[0]))
        XCTAssertTrue(ref[1].isClose(m[1]))
        XCTAssertTrue(ref[2].isClose(m[2]))
    }
}
