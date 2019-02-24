//
//  UnlitOpaquePlugin.swift
//  VidFramework
//
//  Created by David Gavilan on 2019/02/24.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

class UnlitOpaquePlugin: PrimitivePlugin {
    override var label: String {
        get {
            return "UnlitPrimitives"
        }
    }
    override func createPipelineDescriptor(device: MTLDevice, library: MTLLibrary, gBuffer: GBuffer) -> MTLRenderPipelineDescriptor {
        return gBuffer.createUnlitPipelineDescriptor(device: device, library: library, isBlending: false)
    }
    override func createEncoder(commandBuffer: MTLCommandBuffer) -> MTLRenderCommandEncoder? {
        let renderer = Renderer.shared!
        let clear = !renderer.frameState.clearedBackbuffer
        let renderPassDescriptor = renderer.createUnlitRenderPass(clear: clear)
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        if let e = encoder {
            e.label = self.label
            renderer.frameState.clearedBackbuffer = true
        }
        return encoder
    }
}
