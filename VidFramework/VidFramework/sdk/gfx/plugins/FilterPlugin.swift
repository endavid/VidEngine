//
//  FilterPlugin.swift
//  VidFramework
//
//  Created by David Gavilan on 2018/02/28.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

class FilterPlugin: GraphicPlugin {
    fileprivate var filterChains: [FilterChain] = []
    
    func queue(_ filterChain: FilterChain) {
        let alreadyQueued = filterChains.contains { $0 === filterChain }
        if !alreadyQueued {
            filterChains.append(filterChain)
        }
    }
    func dequeue(_ filterChain: FilterChain) {
        let index = filterChains.index { $0 === filterChain }
        if let i = index {
            filterChains.remove(at: i)
        }
    }
    
    override func draw(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer, camera: Camera) {
        for filterChain in filterChains {
            for filter in filterChain.chain {
                if filter.output == nil {
                    continue
                }
                let descriptor = filter.createRenderPassDescriptor()
                guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
                    continue
                }
                encoder.label = filter.id
                encoder.pushDebugGroup(filter.id)
                encoder.setRenderPipelineState(filter.renderPipelineState)
                for i in 0..<filter.inputs.count {
                    encoder.setFragmentTexture(filter.inputs[i], index: i)
                }
                if let buffer = filter.buffer {
                    encoder.setFragmentBuffer(buffer, offset: filter.bufferOffset, index: 0)
                }
                Renderer.shared.fullScreenQuad.draw(encoder: encoder)
                encoder.popDebugGroup()
                encoder.endEncoding()
                filter.postRender()
            }
        }
    }
    
    override func updateBuffers(_ syncBufferIndex: Int, camera _: Camera) {
        var i = filterChains.count - 1
        while i >= 0 {
            let filterChain = filterChains[i]
            filterChain.updateBuffers(syncBufferIndex)
            if filterChain.isCompleted {
                filterChains.remove(at: i)
            }
            i -= 1
        }
    }
}
