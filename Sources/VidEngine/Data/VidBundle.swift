//
//  File.swift
//  
//
//  Created by David Gavilan Ruiz on 29/02/2024.
//

import Foundation

// Bundle.module:
// Xcode creates a resource bundle and an internal static extension on Bundle to access it for each module
// https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package

public class VidBundle {
    public static let metallib: URL? = {
        return Bundle.module.url(forResource: "default", withExtension: "metallib")
    }()
    public static let imageSquareFrame: URL? = {
        return Bundle.module.url(forResource: "squareFrame", withExtension: "png")
    }()
    public static let imageMeasureGrid: URL? = {
        return Bundle.module.url(forResource: "measureGrid", withExtension: "png")
    }()
}
