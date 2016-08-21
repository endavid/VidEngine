//
//  RenderManager.swift
//  VidEngine
//
//  Created by David Gavilan on 8/11/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit
import simd

// this data is update by the game (Model in M-V-C)
// The number of floats must be a multiple of 4
struct GraphicsData {
    var elapsedTime : Float = 0
    var currentPitch : Float = 0
    var currentTouch = float2(0, 0)
    var projectionMatrix = Matrix4()
}

// (View in M-V-C)
class RenderManager {
    static let sharedInstance = RenderManager()
    // triple buffer so we can update stuff in the CPU while the GPU renders for 3 frames
    static let NumSyncBuffers = 3
    private var uniformBuffer: MTLBuffer! = nil
    private var plugins : [GraphicPlugin] = []
    private var syncBufferIndex = 0
    private var depthTex : MTLTexture! = nil
    var data : GraphicsData = GraphicsData()
    var device : MTLDevice! = nil

    
    func getPlugin<T>() -> T? {
        for p in plugins {
            if p is T {
                return p as? T
            }
        }
        return nil
    }
    
    var uniformBufferOffset : Int {
        get {
            return sizeof(GraphicsData) * syncBufferIndex
        }
    }
    
    var depthTexture : MTLTexture {
        get {
            return depthTex
        }
    }
    
    func setUniformBuffer(encoder: MTLRenderCommandEncoder, atIndex: Int) {
        encoder.setVertexBuffer(uniformBuffer, offset: uniformBufferOffset, atIndex: atIndex)
    }
    
    func initManager(device: MTLDevice, view: MTKView) {
        uniformBuffer = device.newBufferWithLength(sizeof(GraphicsData) * RenderManager.NumSyncBuffers, options: [])
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
        for p in plugins {
            p.updateBuffers(syncBufferIndex)
        }
    }
    
    func draw(view: MTKView, commandBuffer: MTLCommandBuffer) {
        guard let currentDrawable = view.currentDrawable else {
            return
        }
        let zWidth = depthTex?.width ?? 0
        let zHeight = depthTex?.height ?? 0
        if let metalLayer = view.layer as? CAMetalLayer {
            let size = metalLayer.drawableSize
            if zWidth != Int(size.width) || zHeight != Int(size.height ){
                createDepthTexture(size)
            }
        }
        let renderPassDescriptor = createRenderPassWithColorAttachmentTexture(currentDrawable.texture)
        let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        renderEncoder.label = "render encoder"
        for plugin in plugins {
            plugin.execute(renderEncoder)
        }
        renderEncoder.endEncoding()
        commandBuffer.presentDrawable(currentDrawable)
        // syncBufferIndex matches the current semaphore controled frame index to ensure writing occurs at the correct region in the vertex buffer
        syncBufferIndex = (syncBufferIndex + 1) % RenderManager.NumSyncBuffers
        commandBuffer.commit()
    }
    
    private func createRenderPassWithColorAttachmentTexture(texture: MTLTexture) -> MTLRenderPassDescriptor {
        let renderPass = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = texture
        renderPass.colorAttachments[0].loadAction = .Clear
        renderPass.colorAttachments[0].storeAction = .Store
        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0.2, 0.5, 0.95, 1.0);
        renderPass.depthAttachment.texture = self.depthTexture
        renderPass.depthAttachment.loadAction = .Clear
        renderPass.depthAttachment.storeAction = .Store
        renderPass.depthAttachment.clearDepth = 1.0
        return renderPass
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
    
    func createPerInstanceUniformsBuffer(label: String, numElements: Int) -> MTLBuffer {
        let buffer = device.newBufferWithLength(numElements * sizeof(PerInstanceUniforms), options: [])
        buffer.label = label
        return buffer
    }
    
    private func createDepthTexture(size: CGSize) {
        let descriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.Depth32Float, width: Int(size.width), height: Int(size.height), mipmapped: false)
        depthTex = device.newTextureWithDescriptor(descriptor)
        depthTex.label = "Main Depth"
    }
}