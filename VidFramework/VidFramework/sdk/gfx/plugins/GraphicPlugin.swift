//
//  GraphicPlugin.swift
//  VidEngine
//
//  Created by David Gavilan on 8/4/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import MetalKit

class GraphicPlugin {
    var label: String {
        get {
            return "Generic"
        }
    }
    /// Empty = nothing to render
    var isEmpty: Bool {
        get {
            return true
        }
    }

    init() {
    }

    init(device: MTLDevice, library: MTLLibrary, view: MTKView) {
    }

    func draw(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer, camera: Camera) {

    }

    // this gets called when we need to update the buffers used by the GPU
    // @param syncBufferIndex the index into a triple-buffer
    func updateBuffers(_ syncBufferIndex: Int, camera: Camera) {

    }
}
