//
//  Color.swift
//  metaltest
//
//  Created by David Gavilan on 6/23/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#else
import Cocoa
typealias UIColor = NSColor
#endif
import simd

extension UIColor {
    public convenience init(argb: UInt32) {
        let alpha = CGFloat(0x000000FF & (argb >> 24)) / 255.0
        let red = CGFloat(0x000000FF & (argb >> 16)) / 255.0
        let green = CGFloat(0x000000FF & (argb >> 8)) / 255.0
        let blue = CGFloat(0x000000FF & argb) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    public var vector: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        get {
            var fRed : CGFloat = 0
            var fGreen : CGFloat = 0
            var fBlue : CGFloat = 0
            var fAlpha : CGFloat = 0
            self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha)
            return (fRed, fGreen, fBlue, fAlpha)
        }
    }
    var argb : UInt32 {
        get {
            let v = self.vector
            let alpha = UInt32(255.0 * v.a)
            let red = UInt32(255.0 * v.r)
            let green = UInt32(255.0 * v.g)
            let blue = UInt32(255.0 * v.b)
            return (alpha << 24 | red << 16 | green << 8 | blue)
        }
    }
    var rgba : UInt32 {
        get {
            let v = self.vector
            let alpha = UInt32(255.0 * v.a)
            let red = UInt32(255.0 * v.r)
            let green = UInt32(255.0 * v.g)
            let blue = UInt32(255.0 * v.b)
            return (red << 24 | green << 16 | blue << 8 | alpha)
        }
    }
}
/// A 3-channel color with an alpha channel
public protocol ColorWithAlpha {
    var raw: simd_float4 { get }
    var color: simd_float3 { get }
    var a: Float { get }
    var rgba16U: UInt64 { get }
    var rgba8U: UInt32 { get }
}




