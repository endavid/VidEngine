//
//  File.swift
//  
//
//  Created by David Gavilan Ruiz on 01/03/2024.
//

#if canImport(UIKit)
import UIKit
typealias VidImage = UIImage
#else
import Cocoa
typealias VidImage = NSImage
extension VidImage {
    var cgImage: CGImage? {
        get {
            var rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            if let representation = representations.first {
                logDebug("createTexture: NSImage \(rect.width)x\(rect.height) pt = \(representation.pixelsWide)x\(representation.pixelsHigh) px; colorSpace: \(representation.colorSpaceName); bitsPerSample: \(representation.bitsPerSample)")
                rect = CGRect(x: 0, y: 0, width: CGFloat(representation.pixelsWide), height: CGFloat(representation.pixelsHigh))
            }
            guard let cgImage = cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
                return nil
            }
            return cgImage
        }
    }
}
#endif
