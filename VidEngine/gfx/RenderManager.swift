//
//  RenderManager.swift
//  VidEngine
//
//  Created by David Gavilan on 8/11/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

// this data is update by the game (Model in M-V-C)
// The number of floats must be a multiple of 4
struct GraphicsData {
    var elapsedTime : Float = 0
    var currentPitch : Float = 0
    var currentTouch = Vector2(x: 0, y: 0)
    var projectionMatrix = Matrix4()
}

// (View in M-V-C)
class RenderManager {
    static let sharedInstance = RenderManager()
    // triple buffer so we can update stuff in the CPU while the GPU renders for 3 frames
    let NumSyncBuffers = 3
    private var uniformBuffer: MTLBuffer! = nil
    private var plugins : [GraphicPlugin] = []
    private var syncBufferIndex = 0
    var data : GraphicsData = GraphicsData()
    var device : MTLDevice! = nil

    var uniformBufferOffset : Int {
        get {
            return sizeof(GraphicsData) * syncBufferIndex
        }
    }
    
    func setUniformBuffer(encoder: MTLRenderCommandEncoder, atIndex: Int) {
        encoder.setVertexBuffer(uniformBuffer, offset: uniformBufferOffset, atIndex: atIndex)
    }
    
    func initManager(device: MTLDevice, view: MTKView) {
        uniformBuffer = device.newBufferWithLength(sizeof(GraphicsData) * NumSyncBuffers, options: [])
        uniformBuffer.label = "uniforms"
        self.device = device
        self.initGraphicPlugins(view)
    }

    private func initGraphicPlugins(view: MTKView) {
        // order is important!
        plugins.append(PrimitivePlugin(device: device, view: view))
        plugins.append(RainPlugin(device: device, view: view))
    }
    
    func updateBuffers() {
        let uniformB = uniformBuffer.contents()
        let uniformData = UnsafeMutablePointer<Float>(uniformB +  sizeof(GraphicsData) * syncBufferIndex)
        memcpy(uniformData, &data, sizeof(GraphicsData))
    }
    
    func draw(view: MTKView, commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor, currentDrawable = view.currentDrawable else {
            return
        }
        let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        renderEncoder.label = "render encoder"
        for plugin in plugins {
            plugin.execute(renderEncoder)
        }
        renderEncoder.endEncoding()
        commandBuffer.presentDrawable(currentDrawable)
        // syncBufferIndex matches the current semaphore controled frame index to ensure writing occurs at the correct region in the vertex buffer
        syncBufferIndex = (syncBufferIndex + 1) % NumSyncBuffers
        commandBuffer.commit()
    }
    
    func createIndexBuffer(label: String, elements: [UInt16]) -> MTLBuffer {
        let buffer = device.newBufferWithBytes(elements, length: elements.count * sizeof(UInt16), options: .CPUCacheModeDefaultCache)
        buffer.label = label
        return buffer
    }
    
    func createTexturedVertexBuffer(label: String, numElements: Int) -> MTLBuffer {
        let buffer = device.newBufferWithLength(numElements * sizeof(TexturedVertex), options: [])
        buffer.label = label
        return buffer
    }
}