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
        let v = simd_float3(Float(c.components![0]), Float(c.components![1]), Float(c.components![2]))
        XCTAssert(rgb.rgb.isClose(v))
    }
    
    func testGamma() {
        let rgb = LinearRGBA(rgb: simd_float3(0.2, 0.3, 0.4))
        let srgb = NormalizedSRGBA(rgba: rgb)
        let linearSpace = CGColorSpace(name: CGColorSpace.linearSRGB)!
        let gammaSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let components: [CGFloat] = [0.2, 0.3, 0.4]
        let c = CGColor(colorSpace: linearSpace, components: components)!
        let cγ = c.converted(to: gammaSpace, intent: .defaultIntent, options: nil)!
        let v = simd_float3(Float(cγ.components![0]), Float(cγ.components![1]), Float(cγ.components![2]))
        XCTAssert(srgb.rgb.isClose(v))
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
        // Model: sRGB D50, Gamma: 1.0
        let xyz = CieXYZ(xyz: simd_float3(0.438191, 0.636189, 0.294722))
        let rgba = LinearRGBA(xyz: xyz, colorSpace: .sRGB)
        XCTAssertEqual(1, rgba.a)
        XCTAssertTrue(IsClose(0.2, rgba.r))
        XCTAssertTrue(IsClose(0.8, rgba.g))
        XCTAssertTrue(IsClose(0.3, rgba.b))
    }
        
    func testsXYZtoRGBMatrix() {
        // XYZ to linear sRGB D50
        let m = RGBColorSpace.sRGB.toRGB
        // matrix ref from http://www.brucelindbloom.com
        let ref = float3x3([
            simd_float3(3.1338561, -0.9787684, 0.0719453),
            simd_float3(-1.6168667, 1.9161415, -0.2289914),
            simd_float3(-0.4906146, 0.0334540, 1.4052427)
            ])
        let e: Float = 0.001
        XCTAssertTrue(ref[0].isClose(m[0], epsilon: e))
        XCTAssertTrue(ref[1].isClose(m[1], epsilon: e))
        XCTAssertTrue(ref[2].isClose(m[2], epsilon: e))
    }
    
    func testXYZUsingCGColor() {
        let red = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        let green = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
        let blue = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
        let xyz = CGColorSpace(name: CGColorSpace.genericXYZ)!
        let r = red.cgColor.converted(to: xyz, intent: .defaultIntent, options: nil)!
        let g = green.cgColor.converted(to: xyz, intent: .defaultIntent, options: nil)!
        let b = blue.cgColor.converted(to: xyz, intent: .defaultIntent, options: nil)!
        let m0 = simd_float3(Float(r.components![0]), Float(r.components![1]), Float(r.components![2]))
        let m1 = simd_float3(Float(g.components![0]), Float(g.components![1]), Float(g.components![2]))
        let m2 = simd_float3(Float(b.components![0]), Float(b.components![1]), Float(b.components![2]))
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
        let rXYZ = simd_float3(0.436, 0.222, 0.014)
        let gXYZ = simd_float3(0.385, 0.717, 0.097)
        let bXYZ = simd_float3(0.143, 0.061, 0.714)
        let e: Float = 0.001
        XCTAssertTrue(rXYZ.isClose(m0, epsilon: e))
        XCTAssertTrue(gXYZ.isClose(m1, epsilon: e))
        XCTAssertTrue(bXYZ.isClose(m2, epsilon: e))
        let m = RGBColorSpace.sRGB.toXYZ
        XCTAssertTrue(rXYZ.isClose(m[0], epsilon: e))
        XCTAssertTrue(gXYZ.isClose(m[1], epsilon: e))
        XCTAssertTrue(bXYZ.isClose(m[2], epsilon: e))
    }
    
    func testWhites() {
        let e: Float = 0.001
        // https://en.wikipedia.org/wiki/Standard_illuminant#White_points_of_standard_illuminants
        // https://en.wikipedia.org/wiki/Illuminant_D65
        XCTAssertTrue(simd_float3(0.950, 1, 1.089).isClose(ReferenceWhite.D65.xyz.xyz, epsilon: e))
        // from the http://www.brucelindbloom.com/index.html?ColorCalculator.html
        XCTAssertTrue(simd_float3(0.964220, 1, 0.825210).isClose(ReferenceWhite.D50.xyz.xyz, epsilon: e))
    }
    
    func testP3ToXYZ() {
        let m = RGBColorSpace.dciP3.toXYZ
        let r = m * simd_float3(1, 0, 0)
        let g = m * simd_float3(0, 1, 0)
        let b = m * simd_float3(0, 0, 1)
        // ref. values from ColorSync Utility calculator
        XCTAssertTrue(simd_float3(0.5151, 0.2412, -0.0011).isClose(r))
        XCTAssertTrue(simd_float3(0.2920, 0.6922, 0.0419).isClose(g))
        XCTAssertTrue(simd_float3(0.1571, 0.0666, 0.7841).isClose(b))
    }
    
    func testSRGBToXYZ() {
        let m = RGBColorSpace.sRGB.toXYZ
        let r = m * simd_float3(1, 0, 0)
        let g = m * simd_float3(0, 1, 0)
        let b = m * simd_float3(0, 0, 1)
        // ref. values from ColorSync Utility calculator
        XCTAssertTrue(simd_float3(0.4361, 0.2225, 0.0139).isClose(r))
        XCTAssertTrue(simd_float3(0.3851, 0.7169, 0.0971).isClose(g))
        XCTAssertTrue(simd_float3(0.1431, 0.0606, 0.7141).isClose(b))
    }
    
    func testSRGBToP3() {
        // values from ColorSync Utility
        let rγ = NormalizedSRGBA(rgb: simd_float3(0.9175, 0.2002, 0.1386))
        let gγ = NormalizedSRGBA(rgb: simd_float3(0.4585, 0.9852, 0.2983))
        let bγ = NormalizedSRGBA(rgb: simd_float3(0, 0, 0.9597))
        // undo gamma
        let r = LinearRGBA(srgba: rγ)
        let g = LinearRGBA(srgba: gγ)
        let b = LinearRGBA(srgba: bγ)
        let ref = float3x3([r.rgb, g.rgb, b.rgb])
        let m = RGBColorSpace.dciP3.toRGB * RGBColorSpace.sRGB.toXYZ
        let e: Float = 0.001
        XCTAssertTrue(ref[0].isClose(m[0], epsilon: e))
        XCTAssertTrue(ref[1].isClose(m[1], epsilon: e))
        XCTAssertTrue(ref[2].isClose(m[2], epsilon: e))
    }
    
    func testSRGBToP3Gamma() {
        // ref. values extracted from Color Sync Utility Calculator
        let m = RGBColorSpace.dciP3.toRGB * RGBColorSpace.sRGB.toXYZ
        let red = NormalizedSRGBA(rgba: LinearRGBA(rgb: m * simd_float3(1,0,0)))
        let green = NormalizedSRGBA(rgba: LinearRGBA(rgb: m * simd_float3(0,1,0)))
        let blue = NormalizedSRGBA(rgba: LinearRGBA(rgb: m * simd_float3(0,0,1)))
        let e: Float = 0.001
        XCTAssertTrue(simd_float3(0.9175, 0.2002, 0.1386).isClose(red.rgb, epsilon: e))
        XCTAssertTrue(simd_float3(0.4585, 0.9852, 0.2983).isClose(green.rgb, epsilon: e))
        XCTAssertTrue(simd_float3(0, 0, 0.9597).isClose(blue.rgb, epsilon: e))
    }
    
    func testSRGBToP3UsingCGColor() {
        let red = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        let green = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
        let blue = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
        let p3 = CGColorSpace(name: CGColorSpace.displayP3)!
        let r = red.cgColor.converted(to: p3, intent: .defaultIntent, options: nil)!
        let g = green.cgColor.converted(to: p3, intent: .defaultIntent, options: nil)!
        let b = blue.cgColor.converted(to: p3, intent: .defaultIntent, options: nil)!
        let rP3 = simd_float3(Float(r.components![0]), Float(r.components![1]), Float(r.components![2]))
        let gP3 = simd_float3(Float(g.components![0]), Float(g.components![1]), Float(g.components![2]))
        let bP3 = simd_float3(Float(b.components![0]), Float(b.components![1]), Float(b.components![2]))
        // values from ColorSync utility (gamma already applied)
        XCTAssertTrue(simd_float3(0.9175, 0.2004, 0.1385).isClose(rP3))
        XCTAssertTrue(simd_float3(0.4584, 0.9853, 0.2982).isClose(gP3))
        XCTAssertTrue(simd_float3(0.0002, 0, 0.9596).isClose(bP3))
    }
    
    func testLabToXYZ() {
        let white = CieXYZ(Lab: CieLab(L: 100, a: 0, b: 0)).xyz
        let red = CieXYZ(Lab: CieLab(L: 50, a: 100, b: 0)).xyz
        let green = CieXYZ(Lab: CieLab(L: 50, a: -50, b: 50)).xyz
        let e: Float = 0.001
        // values from ColorSync utility
        XCTAssertTrue(simd_float3(0.9642, 1, 0.8249).isClose(white, epsilon: e))
        XCTAssertTrue(simd_float3(0.4384, 0.1842, 0.1519).isClose(red, epsilon: e))
        XCTAssertTrue(simd_float3(0.0994, 0.1842, 0.0268).isClose(green, epsilon: e))
    }
    
    func testXYZToLab() {
        let white = CieLab(xyz: CieXYZ(x: 1, y: 1, z: 1)).Lab
        let red = CieLab(xyz: CieXYZ(x: 1, y: 0, z: 0)).Lab
        let gray = CieLab(xyz: CieXYZ(x: 0.5, y: 0.5, z: 0.5)).Lab
        let e: Float = 0.05
        // values from ColorSync utility
        XCTAssertTrue(simd_float3(100.0000, 6.1126, -13.2522).isClose(white, epsilon: e))
        XCTAssertTrue(simd_float3(0, 437.1465, 0).isClose(red, epsilon: e))
        XCTAssertTrue(simd_float3(76.0714, 4.8516, -10.5185).isClose(gray, epsilon: e))
    }
    
    func testP3UIColor() {
        let c = UIColor(displayP3Red: 1, green: 0.5, blue: 0, alpha: 1)
        let v = c.vector
        XCTAssertTrue(IsClose(v.r, 1.07399773597717))
        XCTAssertTrue(IsClose(v.g, 0.462588369846344))
        XCTAssertTrue(IsClose(v.b, -0.210467934608459))
        XCTAssertTrue(IsClose(v.a, 1))
        let nsrgb = NormalizedSRGBA(rgb: simd_float3(1, 0.5, 0))
        let p3 = LinearRGBA(srgba: nsrgb)
        let srgb = RGBColorSpace.sRGB.toRGB * RGBColorSpace.dciP3.toXYZ * p3.rgb
        let cgamma = NormalizedSRGBA(rgba: LinearRGBA(rgb: srgb))
        XCTAssertTrue(IsClose(Float(v.r), cgamma.r))
        XCTAssertTrue(IsClose(Float(v.g), cgamma.g))
        XCTAssertTrue(IsClose(Float(v.b), cgamma.b, epsilon: 0.0005))
        let s = NormalizedSRGBA(c)
        XCTAssertTrue(IsClose(Float(v.r), s.r))
        XCTAssertTrue(IsClose(Float(v.g), s.g))
        XCTAssertTrue(IsClose(Float(v.b), s.b))
        let l = LinearRGBA(srgba: s)
        XCTAssertTrue(IsClose(srgb.x, l.r, epsilon: 0.0005))
        XCTAssertTrue(IsClose(srgb.y, l.g, epsilon: 0.0005))
        XCTAssertTrue(IsClose(srgb.z, l.b, epsilon: 0.0005))
    }
    
    func testToUIColor() {
        let srgb = NormalizedSRGBA(r: 1, g: 0.5, b: 0.2, a: 1)
        let c = srgb.uiColor
        let v = c.vector
        XCTAssertTrue(IsClose(v.r, 1))
        XCTAssertTrue(IsClose(v.g, 0.5))
        XCTAssertTrue(IsClose(v.b, 0.2))
        XCTAssertTrue(IsClose(v.a, 1))
    }
    
    func testHSVtoRGB() {
        XCTAssertTrue(ColorHSV(h: 0, s: 1, v: 0.5).rgb.isClose(simd_float3(0.5, 0, 0)))
        XCTAssertTrue(ColorHSV(h: 0, s: 1, v: 1).rgb.isClose(simd_float3(1, 0, 0)))
        XCTAssertTrue(ColorHSV(h: 30, s: 1, v: 1).rgb.isClose(simd_float3(1, 0.5, 0)))
        XCTAssertTrue(ColorHSV(h: 251, s: 0.5, v: 0.7).rgb.isClose(simd_float3(0.4142, 0.35, 0.7)))
    }
    
    func testRGBtoHSV() {
        XCTAssertTrue(ColorHSV(rgb: simd_float3(0.5, 0, 0)).hsv.isClose(simd_float3(0, 1, 0.5)))
        XCTAssertTrue(ColorHSV(rgb: simd_float3(1, 0, 0)).hsv.isClose(simd_float3(0, 1, 1)))
        XCTAssertTrue(ColorHSV(rgb: simd_float3(1, 0.5, 0)).hsv.isClose(simd_float3(30, 1, 1)))
        // result: (251.006, 0.5, 0.7)
        XCTAssertTrue(ColorHSV(rgb: simd_float3(0.4142, 0.35, 0.7)).hsv.isClose(simd_float3(251, 0.5, 0.7), epsilon: 0.01))

    }
    
}
