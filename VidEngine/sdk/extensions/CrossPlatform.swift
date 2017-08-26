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

    public typealias UXColor = NSColor
    public typealias UXFont = NSFont

#else

    import UIKit
    public typealias UXColor = UIColor
    public typealias UXFont = UIFont

    let UXGraphicsBeginImageContext = UIGraphicsBeginImageContext
    let UXGraphicsGetCurrentContext = UIGraphicsGetCurrentContext
    let UXGraphicsEndImageContext = UIGraphicsEndImageContext

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

extension CGRect {
    var area : CGFloat {
        return width * height
    }
}

extension UXFont {
    internal func estimatedLineWidthForFont() -> CGFloat {
        let myString = "!" as NSString
        let size: CGSize = myString.size(attributes: [NSFontAttributeName: self])
        let estimatedStrokeWidth = Float(size.width)
        return CGFloat(ceilf(estimatedStrokeWidth))
    }

    internal func estimatedGlyphSizeForFont() -> CGSize {
        let exemplarString = "{ǺOJMQYZa@jmqyw" as NSString
        let exemplarStringSize = exemplarString.size(attributes: [NSFontAttributeName: self ])
        let averageGlyphWidth = ceilf(Float(exemplarStringSize.width) / Float(exemplarString.length))
        let maxGlyphHeight = ceilf(Float(exemplarStringSize.height))
        return CGSize(width: CGFloat(averageGlyphWidth), height: CGFloat(maxGlyphHeight))
    }

    internal func isLikelyToFit(size: CGFloat, rect: CGRect) -> Bool {
        guard let trialFont = UXFont(name: fontName, size: size) else {
            return false
        }
        let trialCTFont = CTFontCreateWithName(fontName as CFString, size, nil)
        let fontGlyphCount = CTFontGetGlyphCount(trialCTFont)
        let glyphMargin = trialFont.estimatedLineWidthForFont()
        let averageGlyphSize = trialFont.estimatedGlyphSizeForFont()
        let estimatedGlyphTotalArea = (averageGlyphSize.width + glyphMargin) * (averageGlyphSize.height + glyphMargin) * CGFloat(fontGlyphCount)
        return estimatedGlyphTotalArea < rect.area
    }

    internal func pointSizeThatFitsForFont(rect: CGRect) -> Float {
        var fittedSize = Float(pointSize)
        while isLikelyToFit(size: CGFloat(fittedSize), rect: rect) {
            fittedSize += 1
        }
        while !isLikelyToFit(size: CGFloat(fittedSize), rect: rect) {
            fittedSize -= 1
        }
        return fittedSize
    }
    
    
}

