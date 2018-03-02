//
//  TextureFilter.swift
//  VidFramework
//
//  Created by David Gavilan on 2018/02/27.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

public class TextureFilter {
    public var id: String
    public var input: MTLTexture?
    public var output: MTLTexture?
    public var buffer: MTLBuffer?
    let renderPipelineState: MTLRenderPipelineState
    
    
    public convenience init?(id: String, input: MTLTexture, output: MTLTexture, fragmentFunction: String) {
        guard let renderer = Renderer.shared else {
            return nil
        }
        guard let library = renderer.makeVidLibrary() else {
            return nil
        }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "passThrough2DVertex")
        descriptor.fragmentFunction = library.makeFunction(name: fragmentFunction)
        descriptor.colorAttachments[0].pixelFormat = output.pixelFormat
        descriptor.sampleCount = output.sampleCount
        self.init(id: id, device: renderer.device, descriptor: descriptor)
        self.input = input
        self.output = output
    }
    
    public init?(id: String, device: MTLDevice, descriptor: MTLRenderPipelineDescriptor) {
        self.id = id
        do {
            try renderPipelineState = device.makeRenderPipelineState(descriptor: descriptor)
        } catch let error {
            NSLog("Failed to create pipeline state: \(error.localizedDescription)")
            return nil
        }
    }
    
    func createRenderPassDescriptor() -> MTLRenderPassDescriptor {
        let renderPass = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = output
        renderPass.colorAttachments[0].loadAction = .load
        renderPass.colorAttachments[0].storeAction = .store
        return renderPass
    }
}
