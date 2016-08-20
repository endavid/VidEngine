//
//  Primitive.swift
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

class Primitive {
    let priority : Int
    var transform = Transform()
    
    init(priority: Int) {
        self.priority = priority
    }
    
    func draw(encoder: MTLRenderCommandEncoder) {
    }
    
    func queue() {
        let plugin : PrimitivePlugin? = RenderManager.sharedInstance.getPlugin()
        plugin?.queue(self)
    }
    
    func dequeue() {
        let plugin : PrimitivePlugin? = RenderManager.sharedInstance.getPlugin()
        plugin?.dequeue(self)
    }
    
    // this gets called when we need to update the buffers used by the GPU
    func updateBuffers(syncBufferIndex: Int) {
        
    }
}