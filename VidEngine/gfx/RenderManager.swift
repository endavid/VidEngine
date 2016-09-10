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
    var viewMatrix = Matrix4()
}

// (View in M-V-C)
class RenderManager {
    static let sharedInstance = RenderManager()
    // triple buffer so we can update stuff in the CPU while the GPU renders for 3 frames
    static let NumSyncBuffers = 3
    private var uniformBuffer: MTLBuffer! = nil
    private var plugins : [GraphicPlugin] = []
    private var syncBufferIndex = 0
    private var _gBuffer : GBuffer! = nil
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
    
    var gBuffer : GBuffer {
        get {
            return _gBuffer
        }
    }
    
    func setUniformBuffer(encoder: MTLRenderCommandEncoder, atIndex: Int) {
        encoder.setVertexBuffer(uniformBuffer, offset: uniformBufferOffset, atIndex: atIndex)
    }
    
    func initManager(device: MTLDevice, view: MTKView) {
        uniformBuffer = device.newBufferWithLength(sizeof(GraphicsData) * RenderManager.NumSyncBuffers, options: [])
        uniformBuffer.label = "uniforms"
        // dummy buffer so _gBuffer is never null
        _gBuffer = GBuffer(device: device, size: CGSize(width: 1, height: 1))
        self.device = device
        self.initGraphicPlugins(view)
    }

    private func initGraphicPlugins(view: MTKView) {
        // order is important!
        plugins.append(PrimitivePlugin(device: device, view: view))
        plugins.append(DeferredShadingPlugin(device: device, view: view))
        //plugins.append(RainPlugin(device: device, view: view))
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
        let w = _gBuffer?.width ?? 0
        let h = _gBuffer?.height ?? 0
        if let metalLayer = view.layer as? CAMetalLayer {
            let size = metalLayer.drawableSize
            if w != Int(size.width) || h != Int(size.height ){
                _gBuffer = GBuffer(device: device, size: size)
            }
        }
        for plugin in plugins {
            plugin.draw(currentDrawable, commandBuffer: commandBuffer)
        }
        commandBuffer.presentDrawable(currentDrawable)
        // syncBufferIndex matches the current semaphore controled frame index to ensure writing occurs at the correct region in the vertex buffer
        syncBufferIndex = (syncBufferIndex + 1) % RenderManager.NumSyncBuffers
        commandBuffer.commit()
    }
    
    func createRenderPassWithColorAttachmentTexture(texture: MTLTexture) -> MTLRenderPassDescriptor {
        let renderPass = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = texture
        renderPass.colorAttachments[0].loadAction = .Clear
        renderPass.colorAttachments[0].storeAction = .Store
        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1.0);
        return renderPass
    }
    
    func createRenderPassWithGBuffer(clear: Bool) -> MTLRenderPassDescriptor {
        let renderPass = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = gBuffer.albedoTexture
        renderPass.colorAttachments[0].loadAction = clear ? .Clear : .Load
        renderPass.colorAttachments[0].storeAction = .Store
        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(38/255, 35/255, 35/255, 1.0)
        renderPass.colorAttachments[1].texture = gBuffer.normalTexture
        renderPass.colorAttachments[1].loadAction = clear ? .Clear : .Load
        renderPass.colorAttachments[1].storeAction = .Store
        renderPass.colorAttachments[1].clearColor = MTLClearColorMake(0, 1, 0, 0)
        renderPass.depthAttachment.texture = gBuffer.depthTexture
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
    
    func createTransformsBuffer(label: String, numElements: Int) -> MTLBuffer {
        let buffer = device.newBufferWithLength(numElements * sizeof(Transform), options: [])
        buffer.label = label
        return buffer
    }
    
    func createWhiteTexture() -> MTLTexture {
        let data : [UInt32] = [0xffffffff]
        let texDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.RGBA8Unorm, width: 1, height: 1, mipmapped: false)
        let texture = device.newTextureWithDescriptor(texDescriptor)
        let region = MTLRegionMake2D(0, 0, 1, 1)
        texture.replaceRegion(region, mipmapLevel: 0, withBytes: data, bytesPerRow: 4 * 4)
        return texture
    }
}