//
//  Primitive.swift
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

/// All Primitives should allow instancing
/// To implement instanced rendering: http://metalbyexample.com/instanced-rendering/
class Primitive {
    let priority : Int
    var perInstanceUniforms : [PerInstanceUniforms]
    let uniformBuffer : MTLBuffer!
    
    var numInstances : Int {
        get {
            return perInstanceUniforms.count
        }
    }

    init(priority: Int, numInstances: Int) {
        self.priority = priority
        self.perInstanceUniforms = [PerInstanceUniforms](repeating: PerInstanceUniforms(transform: Transform(), material: Material.white), count: numInstances)
        self.uniformBuffer = RenderManager.sharedInstance.createPerInstanceUniformsBuffer("primUniforms", numElements: RenderManager.NumSyncBuffers * numInstances)
    }
    
    func draw(_ encoder: MTLRenderCommandEncoder) {
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
    func updateBuffers(_ syncBufferIndex: Int) {
        let uniformB = uniformBuffer.contents()
        let uniformData = uniformB.advanced(by: MemoryLayout<PerInstanceUniforms>.size * perInstanceUniforms.count * syncBufferIndex).assumingMemoryBound(to: Float.self)
        memcpy(uniformData, &perInstanceUniforms, MemoryLayout<PerInstanceUniforms>.size * perInstanceUniforms.count)
    }
}
