//
//  ComputePrimitive.swift
//  VidFramework
//
//  Created by David Gavilan on 2018/02/19.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import MetalKit

public class ComputePrimitive {
    fileprivate var updateState: MTLRenderPipelineState! = nil

    var isDone: Bool {
        get {
            return false
        }
    }

    public func queue() {
        let plugin: ComputePlugin? = Renderer.shared.getPlugin()
        plugin?.queue(self)
    }
    public func dequeue() {
        let plugin: ComputePlugin? = Renderer.shared.getPlugin()
        plugin?.dequeue(self)
    }
    init?(function: MTLFunction) {
        guard let device = Renderer.shared.device else {
            return
        }
        let updateStateDescriptor = MTLRenderPipelineDescriptor()
        updateStateDescriptor.vertexFunction = function
        updateStateDescriptor.isRasterizationEnabled = false // vertex output is void
        updateStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb // pixel format needs to be set
        do {
            try updateState = device.makeRenderPipelineState(descriptor: updateStateDescriptor)
        } catch let error {
            NSLog("Failed to create pipeline state, error \(error)")
            return nil
        }
    }
    func compute(encoder: MTLRenderCommandEncoder) {
        encoder.setRenderPipelineState(updateState)
        // set up buffer
        // call shader
        //encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleCount, instanceCount: 1)
    }

    func processResult(_ syncBufferIndex: Int) {

    }

}
