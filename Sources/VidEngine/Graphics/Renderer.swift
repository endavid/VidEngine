//
//  File.swift
//  
//
//  Created by David Gavilan Ruiz on 01/03/2024.
//

import MetalKit
import simd

// this data is updated by the game (Model in M-V-C)
// The number of floats must be a multiple of 4
struct GraphicsData {
    var elapsedTime : Float = 0
    var currentPitch : Float = 0
    var currentTouch = simd_float2(0, 0)
    var projectionMatrix = float4x4()
    var viewMatrix = float4x4()
    var nearTransparency = simd_float4(0, 0, 2, 2)
}

public class Renderer {
    struct FrameState {
        var clearedBackbuffer: Bool
        var clearedGBuffer: Bool
        var clearedLightbuffer: Bool
        var clearedTransparencyBuffer: Bool
        var clearedDrawable: Bool
        init() {
            clearedBackbuffer = false
            clearedGBuffer = false
            clearedLightbuffer = false
            clearedTransparencyBuffer = false
            clearedDrawable = false
        }
    }
    // triple buffer so we can update stuff in the CPU while the GPU renders for 3 frames
    static let numSyncBuffers = 3
    let device: MTLDevice
    let textureSamplers: TextureSamplers
    let textureLibrary = TextureLibrary()
    var clearColor = MTLClearColorMake(38/255, 35/255, 35/255, 1.0)
    var frameState = FrameState()
    
    private var _graphicsDataBuffer: MTLBuffer! = nil
    private var _syncBufferIndex = 0
    private var _gBuffer: GBuffer
    private var _whiteTexture: MTLTexture! = nil
    // Instead of a Render Graph, we have an ordered list of plugins for now
    private var plugins : [GraphicPlugin] = []
    
    var whiteTexture: MTLTexture {
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
            return MemoryLayout<GraphicsData>.size * _syncBufferIndex
        }
    }
    
    var gBuffer : GBuffer {
        get {
            return _gBuffer
        }
    }
    
    func setGraphicsDataBuffer(_ encoder: MTLRenderCommandEncoder, atIndex: Int) {
        encoder.setVertexBuffer(_graphicsDataBuffer, offset: uniformBufferOffset, index: atIndex)
    }
    
    init(_ device: MTLDevice, view: MTKView, width: Int, height: Int) {
        self.device = device
        _graphicsDataBuffer = device.makeBuffer(length: MemoryLayout<GraphicsData>.size * Renderer.numSyncBuffers, options: [])
        _graphicsDataBuffer.label = "GraphicsData"
        // dummy buffer so _gBuffer is never null
        _gBuffer = GBuffer(device: device, size: CGSize(width: 1, height: 1))
        textureSamplers = TextureSamplers(device: device)
    }
    
    // MARK: Render passes
    
    func createUnlitRenderPass(clear: Bool) -> MTLRenderPassDescriptor {
        let rp = MTLRenderPassDescriptor()
        rp.colorAttachments[0].texture = gBuffer.shadedTexture
        rp.colorAttachments[0].loadAction = clear ? .clear : .load
        rp.colorAttachments[0].storeAction = .store
        rp.colorAttachments[0].clearColor = clearColor
        rp.depthAttachment.texture = gBuffer.depthTexture
        rp.depthAttachment.loadAction = clear ? .clear : .load
        rp.depthAttachment.storeAction = .store
        rp.depthAttachment.clearDepth = 1.0
        return rp
    }
    
    func createRenderPassWithGBuffer(clear: Bool) -> MTLRenderPassDescriptor {
        let rp = MTLRenderPassDescriptor()
        rp.colorAttachments[0].texture = gBuffer.albedoTexture
        rp.colorAttachments[0].loadAction = clear ? .clear : .load
        rp.colorAttachments[0].storeAction = .store
        rp.colorAttachments[0].clearColor = clearColor
        rp.colorAttachments[1].texture = gBuffer.normalTexture
        rp.colorAttachments[1].loadAction = clear ? .clear : .load
        rp.colorAttachments[1].storeAction = .store
        rp.colorAttachments[1].clearColor = MTLClearColorMake(0, 1, 0, 0)
        rp.colorAttachments[2].texture = gBuffer.objectTexture
        rp.colorAttachments[2].loadAction = clear ? .clear : .load
        rp.colorAttachments[2].storeAction = .store
        rp.depthAttachment.texture = gBuffer.depthTexture
        rp.depthAttachment.loadAction = clear ? .clear : .load
        rp.depthAttachment.storeAction = .store
        rp.depthAttachment.clearDepth = 1.0
        rp.stencilAttachment.texture = gBuffer.stencilTexture
        rp.stencilAttachment.loadAction = clear ? .clear : .load
        rp.stencilAttachment.storeAction = .store
        rp.stencilAttachment.clearStencil = LightMask.none.rawValue
        return rp
    }
    
    // Transparency
    func createOITRenderPass(clear: Bool, clearDepth: Bool) -> MTLRenderPassDescriptor {
        let rp = MTLRenderPassDescriptor()
        rp.colorAttachments[0].texture = gBuffer.lightTexture
        rp.colorAttachments[0].loadAction = clear ? .clear : .load
        rp.colorAttachments[0].storeAction = .store
        // important for OIT!
        rp.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
        rp.colorAttachments[1].texture = gBuffer.revealTexture
        rp.colorAttachments[1].loadAction = clear ? .clear : .load
        rp.colorAttachments[1].storeAction = .store
        // alpha is stored in Red channel; it's a R16 texture
        rp.colorAttachments[1].clearColor = MTLClearColorMake(1, 1, 1, 1)
        rp.depthAttachment.texture = gBuffer.depthTexture
        rp.depthAttachment.loadAction = clearDepth ? .clear : .load
        rp.depthAttachment.storeAction = .dontCare
        rp.depthAttachment.clearDepth = 1.0
        return rp
    }
    
    // MARK: Buffers
    
    func createIndexBuffer(_ label: String, elements: [UInt16]) -> MTLBuffer {
        let buffer = device.makeBuffer(bytes: elements, length: elements.count * MemoryLayout<UInt16>.size, options: MTLResourceOptions())
        buffer?.label = label
        return buffer!
    }
    
    func createTexturedVertexBuffer(_ label: String, numElements: Int) -> MTLBuffer {
        let buffer = device.makeBuffer(length: numElements * MemoryLayout<TexturedVertex>.stride, options: [])
        buffer?.label = label
        return buffer!
    }
}
