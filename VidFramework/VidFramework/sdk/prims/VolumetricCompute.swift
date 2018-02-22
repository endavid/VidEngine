//
//  VolumetricCompute.swift
//  VidFramework
//
//  Created by David Gavilan on 2018/02/19.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import Foundation

public class VolumetricCompute: ComputePrimitive {
    let width: Int
    let height: Int
    let depth: Int
    
    init?(function: MTLFunction, width: Int, height: Int, depth: Int) {
        if width <= 0 || height <= 0 || depth <= 0 {
            NSLog("VolumetricCompute: wrong dimensions")
            return nil
        }
        self.width = width
        self.height = height
        self.depth = depth
        super.init(function: function)
    }
}
