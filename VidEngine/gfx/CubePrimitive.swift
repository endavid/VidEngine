//
//  CubePrimitive.swift
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

class CubePrimitive : CubeSetPrimitive {
    init(priority: Int) {
        super.init(priority: priority, numInstances: 1)
    }
    
    override func updateBuffers(syncBufferIndex: Int) {
        var u = self.transform
        let uniformB = uniformBuffer.contents()
        let uniformData = UnsafeMutablePointer<Float>(uniformB +  sizeof(Transform) * syncBufferIndex)
        memcpy(uniformData, &u, sizeof(Transform))
    }
}