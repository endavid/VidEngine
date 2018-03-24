//
//  ComputePlugin.swift
//  VidFramework
//
//  Created by David Gavilan on 2018/02/19.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

class ComputePlugin: GraphicPlugin {
    fileprivate var computePrimitives: [ComputePrimitive] = []
    
    func queue(_ prim: ComputePrimitive) {
        let alreadyQueued = computePrimitives.contains { $0 === prim }
        if !alreadyQueued {
            computePrimitives.append(prim)
        }
    }
    func dequeue(_ prim: ComputePrimitive) {
        let index = computePrimitives.index { $0 === prim }
        if let i = index {
            computePrimitives.remove(at: i)
        }
    }
    
    override func draw(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer, camera: Camera) {
        if computePrimitives.isEmpty {
            return
        }
        let renderPassDescriptor = Renderer.shared.createRenderPassWithColorAttachmentTexture(drawable.texture, clear: false)
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        encoder.pushDebugGroup("ComputePrimitives")
        for prim in computePrimitives {
            prim.compute(encoder: encoder)
        }
        encoder.popDebugGroup()
        encoder.endEncoding()
    }
    
    override func updateBuffers(_ syncBufferIndex: Int, camera _: Camera) {
        for prim in computePrimitives {
            prim.processResult(syncBufferIndex)
            if prim.isDone {
                dequeue(prim)
            }
        }
    }
}
