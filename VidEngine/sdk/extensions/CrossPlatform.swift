//
//  CrossPlatform.swift
//  VidEngine
//
//  Created by Adam Nemecek on 8/26/17.
//  Copyright © 2017 David Gavilan. All rights reserved.
//

import Foundation

#if os(macOS)
    import Cocoa

    extension NSImage {
        // somehow OSX does not provide CGImage property
        var cgImage: CGImage? {
            return tiffRepresentation.flatMap {
                CGImageSourceCreateWithData($0 as CFData, nil).flatMap {
                    guard CGImageSourceGetCount($0) > 0 else { return nil }
                    return CGImageSourceCreateImageAtIndex($0, 0, nil)
                }
            }
        }
    }

    typealias UXColor = NSColor
#else

    import UIKit
    typealias UXColor = UIColor

#endif

extension UXColor {
    convenience init(argb: UInt32) {
        let alpha = CGFloat(0x000000FF & (argb >> 24)) / 255.0
        let red = CGFloat(0x000000FF & (argb >> 16)) / 255.0
        let green = CGFloat(0x000000FF & (argb >> 8)) / 255.0
        let blue = CGFloat(0x000000FF & argb) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    var argb : UInt32 {
        get {
            var fRed : CGFloat = 0
            var fGreen : CGFloat = 0
            var fBlue : CGFloat = 0
            var fAlpha : CGFloat = 0
            self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha)
            let alpha = UInt32(255.0 * fAlpha)
            let red = UInt32(255.0 * fRed)
            let green = UInt32(255.0 * fGreen)
            let blue = UInt32(255.0 * fBlue)
            return (alpha << 24 | red << 16 | green << 8 | blue)
        }
    }
    var rgba : UInt32 {
        get {
            var fRed : CGFloat = 0
            var fGreen : CGFloat = 0
            var fBlue : CGFloat = 0
            var fAlpha : CGFloat = 0
            self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha)
            let alpha = UInt32(255.0 * fAlpha)
            let red = UInt32(255.0 * fRed)
            let green = UInt32(255.0 * fGreen)
            let blue = UInt32(255.0 * fBlue)
            return (red << 24 | green << 16 | blue << 8 | alpha)
        }
    }
}
