//
//  TouchPlugin.swift
//  VidFramework
//
//  Created by David Gavilan on 2019/04/19.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import Foundation
import Metal
import MetalKit

class TouchPlugin: GraphicPlugin {
    var readPointsState: MTLRenderPipelineState!
    private var worldTouches: [WorldTouch] = []
    
    override var label: String {
        get {
            return "Touch"
        }
    }
    
    override var isEmpty: Bool {
        get {
            return worldTouches.isEmpty
        }
    }
    
    func queue(_ worldTouch: WorldTouch) {
        let alreadyQueued = worldTouches.contains { $0 === worldTouch }
        if !alreadyQueued {
            worldTouches.append(worldTouch)
        }
    }
    
    func dequeue(_ worldTouch: WorldTouch) {
        let index = worldTouches.firstIndex { $0 === worldTouch }
        if let i = index {
            worldTouches.remove(at: i)
        }
    }
    
    fileprivate func createReadPointsDescriptor(library: MTLLibrary, pixelFormat: MTLPixelFormat) -> MTLRenderPipelineDescriptor {
        let fn = library.makeFunction(name: "getTouchedPoints")!
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = fn
        // vertex output is void
        desc.isRasterizationEnabled = false
        // pixel format needs to be set
        desc.colorAttachments[0].pixelFormat = pixelFormat
        return desc
    }
    
    override init(device: MTLDevice, library: MTLLibrary, view: MTKView) {
        super.init(device: device, library: library, view: view)
        let readPointsDesc = createReadPointsDescriptor(library: library, pixelFormat: view.colorPixelFormat)
        do {
            try readPointsState = device.makeRenderPipelineState(descriptor: readPointsDesc)
        } catch let error {
            logInitError(error)
        }
    }
    
    override func draw(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer, camera: Camera) {
        if isEmpty {
            return
        }
        guard let renderer = Renderer.shared else {
            return
        }
        let renderPassDescriptor = renderer.createRenderPassWithColorAttachmentTexture(drawable.texture, clear: false)
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        encoder.label = self.label
        encoder.setRenderPipelineState(readPointsState)
        renderer.setGraphicsDataBuffer(encoder, atIndex: 1)
        encoder.setVertexTexture(renderer.gBuffer.objectTexture, index: 0)
        encoder.setVertexTexture(renderer.gBuffer.depthTexture, index: 1)
        for worldTouch in worldTouches {
            worldTouch.readSamples(encoder: encoder)
        }
        encoder.endEncoding()
    }
    
    override func updateBuffers(_ syncBufferIndex: Int, camera _: Camera) {
        for worldTouch in worldTouches {
            worldTouch.updateBuffers(syncBufferIndex)
        }
    }
}
