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
    
    func testInverseGamma() {
        let srgb = NormalizedSRGBA(r: 0.2, g: 0.3, b: 0.4, a: 1.0)
        let rgb = LinearRGBA(srgba: srgb)
        let uiColor = UIColor(red: 0.2, green: 0.3, blue: 0.4, alpha: 1.0)
        let linearSpace = CGColorSpace(name: CGColorSpace.linearSRGB)!
        let c = uiColor.cgColor.converted(to: linearSpace, intent: .defaultIntent, options: nil)!
        let v = float3(Float(c.components![0]), Float(c.components![1]), Float(c.components![2]))
        print("\(v) \(rgb.rgb))")
        XCTAssert(rgb.rgb.isClose(v))
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
    
    func testXYZUsingCGColor() {
        let red = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        let green = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
        let blue = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
        let xyz = CGColorSpace(name: CGColorSpace.genericXYZ)!
        let r = red.cgColor.converted(to: xyz, intent: .defaultIntent, options: nil)!
        let g = green.cgColor.converted(to: xyz, intent: .defaultIntent, options: nil)!
        let b = blue.cgColor.converted(to: xyz, intent: .defaultIntent, options: nil)!
        let m0 = float3(Float(r.components![0]), Float(r.components![1]), Float(r.components![2]))
        let m1 = float3(Float(g.components![0]), Float(g.components![1]), Float(g.components![2]))
        let m2 = float3(Float(b.components![0]), Float(b.components![1]), Float(b.components![2]))
        // linear sRGB to XYZ
        // sRGB D65 to XYZ is http://www.brucelindbloom.com
        // 0.4124564  0.3575761  0.1804375
        // 0.2126729  0.7151522  0.0721750
        // 0.0193339  0.1191920  0.9503041
        // sRGB D50 to XYZ is,
        //  0.4360747  0.3850649  0.1430804
        //  0.2225045  0.7168786  0.0606169
        //  0.0139322  0.0971045  0.7141733
        // from sRGB Profile.icc
        let rXYZ = float3(0.436, 0.222, 0.014)
        let gXYZ = float3(0.385, 0.717, 0.097)
        let bXYZ = float3(0.143, 0.061, 0.714)
        XCTAssertTrue(rXYZ.isClose(m0))
        XCTAssertTrue(gXYZ.isClose(m1))
        XCTAssertTrue(bXYZ.isClose(m2))
        let m = RGBColorSpace.sRGB.toXYZ
        XCTAssertTrue(rXYZ.isClose(m[0]))
        XCTAssertTrue(gXYZ.isClose(m[1]))
        XCTAssertTrue(bXYZ.isClose(m[2]))
    }
    
    func testP3ToSrgb() {
        let m = RGBColorSpace.sRGB.toRGB * RGBColorSpace.dciP3.toXYZ
        let ref = float3x3([
            float3(1.22494, -0.0420569, -0.0196376),
            float3(-0.22494, 1.04206, -0.078636),
            float3(4.61524e-08, 1.34893e-08, 1.09827)
        ])
        XCTAssertTrue(ref[0].isClose(m[0]))
        XCTAssertTrue(ref[1].isClose(m[1]))
        XCTAssertTrue(ref[2].isClose(m[2]))
    }
    
    func testSrgbToP3Gamma() {
        // ref. values extracted from Color Sync Utility Calculator
        let m = RGBColorSpace.dciP3.toRGB * RGBColorSpace.sRGB.toXYZ
        let red = NormalizedSRGBA(rgba: LinearRGBA(rgb: m * float3(1,0,0)))
        let green = NormalizedSRGBA(rgba: LinearRGBA(rgb: m * float3(0,1,0)))
        let blue = NormalizedSRGBA(rgba: LinearRGBA(rgb: m * float3(0,0,1)))
        print(red.rgb)
        print(green.rgb)
        print(blue.rgb)
        let e: Float = 0.04 // error is kinda big... :(
        XCTAssertTrue(float3(0.9175, 0.2002, 0.1386).isClose(red.rgb, epsilon: e))
        XCTAssertTrue(float3(0.4585, 0.9852, 0.2983).isClose(green.rgb, epsilon: e))
        XCTAssertTrue(float3(0, 0, 0.9597).isClose(blue.rgb, epsilon: e))
    }
    
    func testSrgbToP3UsingCGColor() {
        let red = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        let green = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
        let blue = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
        let p3 = CGColorSpace(name: CGColorSpace.displayP3)!
        let r = red.cgColor.converted(to: p3, intent: .defaultIntent, options: nil)!
        let g = green.cgColor.converted(to: p3, intent: .defaultIntent, options: nil)!
        let b = blue.cgColor.converted(to: p3, intent: .defaultIntent, options: nil)!
        let rP3 = float3(Float(r.components![0]), Float(r.components![1]), Float(r.components![2]))
        let gP3 = float3(Float(g.components![0]), Float(g.components![1]), Float(g.components![2]))
        let bP3 = float3(Float(b.components![0]), Float(b.components![1]), Float(b.components![2]))
        XCTAssertTrue(float3(0.9175, 0.2002, 0.1386).isClose(rP3))
        XCTAssertTrue(float3(0.4585, 0.9852, 0.2983).isClose(gP3))
        XCTAssertTrue(float3(0, 0, 0.9597).isClose(bP3))
    }
}
