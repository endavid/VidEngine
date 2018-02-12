//
//  RenderManager.swift
//  VidEngine
//
//  Created by David Gavilan on 8/11/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit
import QuartzCore
import simd

// this data is update by the game (Model in M-V-C)
// The number of floats must be a multiple of 4
struct GraphicsData {
    var elapsedTime : Float = 0
    var currentPitch : Float = 0
    var currentTouch = float2(0, 0)
    var projectionMatrix = float4x4()
    var viewMatrix = float4x4()
}

public enum RendererError: Error {
    case
    MissingDevice
}

// (View in M-V-C)
class RenderManager {
    static let sharedInstance = RenderManager()
    // triple buffer so we can update stuff in the CPU while the GPU renders for 3 frames
    static let NumSyncBuffers = 3
    fileprivate var graphicsDataBuffer: MTLBuffer! = nil
    fileprivate var plugins : [GraphicPlugin] = []
    fileprivate var syncBufferIndex = 0
    fileprivate var _gBuffer : GBuffer! = nil
    fileprivate var _whiteTexture : MTLTexture! = nil
    fileprivate var _fullScreenQuad : FullScreenQuad! = nil
    var graphicsData : GraphicsData = GraphicsData()
    var device : MTLDevice! = nil
    var camera : Camera = Camera()
    let textureLibrary = TextureLibrary()
    
    var whiteTexture : MTLTexture {
        get {
            return _whiteTexture
        }
    }
    
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
            return MemoryLayout<GraphicsData>.size * syncBufferIndex
        }
    }
    
    var gBuffer : GBuffer {
        get {
            return _gBuffer
        }
    }
    
    var fullScreenQuad : FullScreenQuad {
        get {
            return _fullScreenQuad
        }
    }
    
    func setGraphicsDataBuffer(_ encoder: MTLRenderCommandEncoder, atIndex: Int) {
        encoder.setVertexBuffer(graphicsDataBuffer, offset: uniformBufferOffset, index: atIndex)
    }
    
    func initManager(_ device: MTLDevice, view: MTKView) {
        graphicsDataBuffer = device.makeBuffer(length: MemoryLayout<GraphicsData>.size * RenderManager.NumSyncBuffers, options: [])
        graphicsDataBuffer.label = "GraphicsData"
        // dummy buffer so _gBuffer is never null
        _gBuffer = GBuffer(device: device, size: CGSize(width: 1, height: 1))
        self.device = device
        _whiteTexture = createWhiteTexture()
        _fullScreenQuad = FullScreenQuad(device: device)
        self.initGraphicPlugins(view)
    }

    fileprivate func initGraphicPlugins(_ view: MTKView) {
        // @todo library should come from a different bundle when making the engine a Framework
        if let library = device.makeDefaultLibrary() {
            // order is important!
            plugins.append(PrimitivePlugin(device: device, library: library, view: view))
            plugins.append(DeferredShadingPlugin(device: device, library: library, view: view))
            plugins.append(UnlitTransparencyPlugin(device: device, library: library, view: view))
            plugins.append(ResolveWeightBlendedTransparency(device: device, library: library, view: view))
            plugins.append(PostEffectPlugin(device: device, library: library, view: view))
            //plugins.append(RainPlugin(device: device, library: library, view: view))
            plugins.append(Primitive2DPlugin(device: device, library: library, view: view))
        } else {
            NSLog("initGraphicPlugins: failed to make shader library")
        }
    }
    
    func updateBuffers() {
        let uniformB = graphicsDataBuffer.contents()
        let uniformData = uniformB.advanced(by: MemoryLayout<GraphicsData>.size * syncBufferIndex).assumingMemoryBound(to: Float.self)
        graphicsData.projectionMatrix = camera.projectionMatrix
        graphicsData.viewMatrix = camera.viewTransformMatrix
        memcpy(uniformData, &graphicsData, MemoryLayout<GraphicsData>.size)
        for p in plugins {
            p.updateBuffers(syncBufferIndex)
        }
    }
    
    func draw(_ view: MTKView, commandBuffer: MTLCommandBuffer) {
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
            plugin.draw(drawable: currentDrawable, commandBuffer: commandBuffer, camera: camera)
        }
        commandBuffer.present(currentDrawable)
        // syncBufferIndex matches the current semaphore controled frame index to ensure writing occurs at the correct region in the vertex buffer
        syncBufferIndex = (syncBufferIndex + 1) % RenderManager.NumSyncBuffers
        commandBuffer.commit()
    }
    
    func createRenderPassWithColorAttachmentTexture(_ texture: MTLTexture, clear: Bool) -> MTLRenderPassDescriptor {
        let renderPass = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = texture
        renderPass.colorAttachments[0].loadAction = clear ? .clear : .load
        renderPass.colorAttachments[0].storeAction = .store
        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1.0);
        return renderPass
    }
    
    
    func createUnlitRenderPass() -> MTLRenderPassDescriptor {
        // load color and depth, assuming they've been cleared before
        let rp = MTLRenderPassDescriptor()
        rp.colorAttachments[0].texture = gBuffer.shadedTexture
        rp.colorAttachments[0].loadAction = .load
        rp.colorAttachments[0].storeAction = .store
        rp.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1.0)
        rp.depthAttachment.texture = gBuffer.depthTexture
        rp.depthAttachment.loadAction = .load
        rp.depthAttachment.storeAction = .store
        rp.depthAttachment.clearDepth = 1.0
        return rp
    }
    
    // Transparency
    func createOITRenderPass(clear: Bool) -> MTLRenderPassDescriptor {
        let rp = MTLRenderPassDescriptor()
        rp.colorAttachments[0].texture = gBuffer.lightTexture
        rp.colorAttachments[0].loadAction = clear ? .clear : .load
        rp.colorAttachments[0].storeAction = .store
        rp.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1) // important for OIT!
        rp.colorAttachments[1].texture = gBuffer.revealTexture
        rp.colorAttachments[1].loadAction = clear ? .clear : .load
        rp.colorAttachments[1].storeAction = .store
        rp.colorAttachments[1].clearColor = MTLClearColorMake(0, 0, 0, 1)
        rp.depthAttachment.texture = gBuffer.depthTexture
        rp.depthAttachment.loadAction = .load
        rp.depthAttachment.storeAction = .dontCare
        return rp
    }
    
    func createRenderPassWithGBuffer(_ clear: Bool) -> MTLRenderPassDescriptor {
        let renderPass = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = gBuffer.albedoTexture
        renderPass.colorAttachments[0].loadAction = clear ? .clear : .load
        renderPass.colorAttachments[0].storeAction = .store
        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(38/255, 35/255, 35/255, 1.0)
        renderPass.colorAttachments[1].texture = gBuffer.normalTexture
        renderPass.colorAttachments[1].loadAction = clear ? .clear : .load
        renderPass.colorAttachments[1].storeAction = .store
        renderPass.colorAttachments[1].clearColor = MTLClearColorMake(0, 1, 0, 0)
        renderPass.depthAttachment.texture = gBuffer.depthTexture
        renderPass.depthAttachment.loadAction = .clear
        renderPass.depthAttachment.storeAction = .store
        renderPass.depthAttachment.clearDepth = 1.0
        return renderPass
    }

    
    func createIndexBuffer(_ label: String, elements: [UInt16]) -> MTLBuffer {
        let buffer = device.makeBuffer(bytes: elements, length: elements.count * MemoryLayout<UInt16>.size, options: MTLResourceOptions())
        buffer?.label = label
        return buffer!
    }
    
    func createTexturedVertexBuffer(_ label: String, numElements: Int) -> MTLBuffer {
        let buffer = device.makeBuffer(length: numElements * MemoryLayout<TexturedVertex>.size, options: [])
        buffer?.label = label
        return buffer!
    }
    
    func createPerInstanceUniformsBuffer(_ label: String, numElements: Int) -> MTLBuffer {
        let buffer = device.makeBuffer(length: numElements * MemoryLayout<PerInstanceUniforms>.size, options: [])
        buffer?.label = label
        return buffer!
    }
    
    func createTransformsBuffer(_ label: String, numElements: Int) -> MTLBuffer {
        let buffer = device.makeBuffer(length: numElements * MemoryLayout<Transform>.size, options: [])
        buffer?.label = label
        return buffer!
    }
    
    private func createWhiteTexture() -> MTLTexture {
        let data : [UInt32] = [0xffffffff]
        let texDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 1, height: 1, mipmapped: false)
        let texture = device.makeTexture(descriptor: texDescriptor)
        let region = MTLRegionMake2D(0, 0, 1, 1)
        texture?.replace(region: region, mipmapLevel: 0, withBytes: data, bytesPerRow: 4 * 4)
        return texture!
    }
}
