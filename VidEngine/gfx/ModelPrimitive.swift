//
//  ModelPrimitive.swift
//  VidEngine
//
//  Created by David Gavilan on 9/1/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

class ModelPrimitive : Primitive {
    
    init(assetName: String, priority: Int, numInstances: Int) {
        super.init(priority: priority, numInstances: numInstances)
    }
}
