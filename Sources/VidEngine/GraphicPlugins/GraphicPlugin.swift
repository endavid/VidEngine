//
//  GraphicPlugin.swift
//  VidEngine
//
//  Created by David Gavilan on 8/4/16.
//

import Metal
import MetalKit

protocol GraphicPlugin {
    var label: String { get }
    var isEmpty: Bool { get }
    var isEnabled: Bool { get set }
    /// this gets called when we need to update the buffers used by the GPU
    /// @param syncBufferIndex the index into a triple-buffer
    func updateBuffers(_ syncBufferIndex: Int, camera: Camera)
    func draw(renderer: Renderer, drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer, camera: Camera)
}

func logInitError(label: String, error: Error) {
    NSLog("Failed to initialize \(label) plugin: \(error.localizedDescription)")
}
