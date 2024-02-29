//
//  ColorCategory.swift
//  VidFramework
//
//  Created by David Gavilan on 2018/03/11.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import Foundation

public enum UniversalColorCategoryEx: Int {
    case
    black = 1,
    gray,
    white,
    brown,
    lightBrown,
    pink,
    orange,
    purple,
    azure,
    blue,
    yellow,
    green,
    red
}

public class UniversalColorCategorization {
    private var lut: [UInt8]
    
    public init?() {
        guard let url = VidBundle.rawCC14 else {
            return nil
        }
        guard let data = NSData(contentsOf: url) else {
            return nil
        }
        lut = [UInt8](repeating: 0, count: data.length)
        data.getBytes(&lut, length: data.length)
    }
    
    public func getCategory(_ color: NormalizedSRGBA) -> UniversalColorCategoryEx? {
        // the lut has only 5 bits -- quantize
        let r = Int(31 * color.r)
        let g = Int(31 * color.g)
        let b = Int(31 * color.b)
        let i = r*32*32+g*32+b
        let cat = Int(lut[i])
        return UniversalColorCategoryEx(rawValue: cat)
    }
}
