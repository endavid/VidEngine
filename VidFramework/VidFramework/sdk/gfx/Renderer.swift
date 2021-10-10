//
//  RenderManager.swift
//  VidEngine
//
//  Created by David Gavilan on 8/11/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit
import ARKit
import QuartzCore
import simd

// this data is update by the game (Model in M-V-C)
// The number of floats must be a multiple of 4
struct GraphicsData {
    var elapsedTime : Float = 0
    var currentPitch : Float = 0
    var currentTouch = simd_float2(0, 0)
    var projectionMatrix = float4x4()
    var viewMatrix = float4x4()
    var nearTransparency = simd_float4(0, 0, 2, 2)
}

public enum RendererError: Error {
    case
    MissingDevice
}

// (View in M-V-C)
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
    static var shared: Renderer! = nil
    // triple buffer so we can update stuff in the CPU while the GPU renders for 3 frames
    static let NumSyncBuffers = 3
    fileprivate var graphicsDataBuffer: MTLBuffer! = nil
    fileprivate var plugins : [GraphicPlugin] = []
    fileprivate var syncBufferIndex = 0
    fileprivate var _gBuffer : GBuffer! = nil
    fileprivate var _whiteTexture: MTLTexture! = nil
    fileprivate var _clearTexture: MTLTexture! = nil
    fileprivate lazy var _fullScreenQuad : FullScreenQuad = {
        return FullScreenQuad(device: self.device)
    }()
    var graphicsData : GraphicsData = GraphicsData()
    var device : MTLDevice! = nil
    var camera : Camera = Camera()
    let textureLibrary = TextureLibrary()
    let textureSamplers: TextureSamplers
    var clearColor = MTLClearColorMake(38/255, 35/255, 35/255, 1.0)
    var frameState = FrameState()
    var arSession: ARSession?
    var capturedImageTextureY: CVMetalTexture?
    var capturedImageTextureCbCr: CVMetalTexture?

    var whiteTexture: MTLTexture {
        get {
            return _whiteTexture
        }
    }
    var clearTexture: MTLTexture {
        get {
            return _clearTexture
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
    
    init(_ device: MTLDevice, view: MTKView, doAR: Bool) {
        graphicsDataBuffer = device.makeBuffer(length: MemoryLayout<GraphicsData>.size * Renderer.NumSyncBuffers, options: [])
        graphicsDataBuffer.label = "GraphicsData"
        // dummy buffer so _gBuffer is never null
        _gBuffer = GBuffer(device: device, size: CGSize(width: 1, height: 1))
        self.device = device
        _whiteTexture = TextureUtils.createTexture(device: device, color: 0xffffffff)
        _clearTexture = TextureUtils.createTexture(device: device, color: 0x0)
        textureSamplers = TextureSamplers(device: device)
        self.initGraphicPlugins(view, doAR: doAR)
        if doAR {
            arSession = ARSession()
        }
    }

    func makeVidLibrary() -> MTLLibrary? {
        let metallib = "VidMetalLib"
        do {
            let bundle = try FrameworkBundle.mainBundle()
            guard let libfile = bundle.path(forResource: metallib, ofType: "metallib") else {
                NSLog("Missing shader files: \(metallib).metallib")
                return nil
            }
            let library = try device.makeLibrary(filepath: libfile)
            return library
        } catch FrameworkError.missing(let what) {
            NSLog("No such bundle: \(what)")
            return nil
        } catch {
            NSLog("makeLibrary failed for \(metallib).metallib")
            return nil
        }
    }
    
    fileprivate func initGraphicPlugins(_ view: MTKView, doAR: Bool) {
        guard let library = makeVidLibrary() else {
            return
        }
        // order is important!
        plugins.append(FilterPlugin())
        if (doAR) {
            plugins.append(ARPlugin(device: device, library: library, view: view))
        }
        plugins.append(LitOpaquePlugin(device: device, library: library, view: view, gBuffer: gBuffer))
        plugins.append(DeferredLightingPlugin(device: device, library: library, view: view, gBuffer: gBuffer))
        plugins.append(DeferredShadingPlugin(device: device, library: library, view: view, gBuffer: gBuffer))
        plugins.append(UnlitOpaquePlugin(device: device, library: library, view: view, gBuffer: gBuffer))
        plugins.append(UnlitTransparencyPlugin(device: device, library: library, view: view, gBuffer: gBuffer))
        plugins.append(DownsamplePlugin(device: device, library: library, view: view, gBuffer: gBuffer, downscaleLevel: 2))
        plugins.append(PostEffectPlugin(device: device, library: library, view: view, blend: doAR))
        plugins.append(TouchPlugin(device: device, library: library, view: view))
        plugins.append(RainPlugin(device: device, library: library, view: view))
        plugins.append(Primitive2DPlugin(device: device, library: library, view: view))
    }
    
    func updateBuffers() {
        let uniformB = graphicsDataBuffer.contents()
        let uniformData = uniformB.advanced(by: MemoryLayout<GraphicsData>.size * syncBufferIndex).assumingMemoryBound(to: Float.self)
        graphicsData.projectionMatrix = camera.projection
        graphicsData.viewMatrix = camera.viewMatrix
        memcpy(uniformData, &graphicsData, MemoryLayout<GraphicsData>.size)
        for p in plugins {
            p.updateBuffers(syncBufferIndex, camera: camera)
        }
    }
    
    func draw(_ view: MTKView, commandBuffer: MTLCommandBuffer) {
        guard let currentDrawable = view.currentDrawable else {
            return
        }
        let w = _gBuffer?.width ?? 0
        let h = _gBuffer?.height ?? 0
        if #available(iOS 13.0, *) {
            if let metalLayer = view.layer as? CAMetalLayer {
                let size = metalLayer.drawableSize
                if w != Int(size.width) || h != Int(size.height ){
                    _gBuffer = GBuffer(device: device, size: size)
                }
            }
        } else {
            // Fallback on earlier versions
        }
        // reset state
        frameState = FrameState()
        // process all plugins
        for plugin in plugins {
            plugin.draw(drawable: currentDrawable, commandBuffer: commandBuffer, camera: camera)
        }
        commandBuffer.present(currentDrawable)
        // syncBufferIndex matches the current semaphore controled frame index to ensure writing occurs at the correct region in the vertex buffer
        syncBufferIndex = (syncBufferIndex + 1) % Renderer.NumSyncBuffers
        commandBuffer.commit()
    }
    
    func createRenderPassWithColorAttachmentTexture(_ texture: MTLTexture, clear: Bool) -> MTLRenderPassDescriptor {
        let renderPass = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = texture
        renderPass.colorAttachments[0].loadAction = clear ? .clear : .load
        renderPass.colorAttachments[0].storeAction = .store
        renderPass.colorAttachments[0].clearColor = clearColor
        return renderPass
    }
    
    
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
    
    func createLightAccumulationRenderPass(clear: Bool, color: Bool, depth: Bool, stencil: Bool) -> MTLRenderPassDescriptor {
        let rp = MTLRenderPassDescriptor()
        if color {
            rp.colorAttachments[0].texture = gBuffer.lightTexture
            rp.colorAttachments[0].loadAction = clear ? .clear : .load
            rp.colorAttachments[0].storeAction = .store
            rp.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
        }
        if depth {
            rp.depthAttachment.texture = gBuffer.depthTexture
            rp.depthAttachment.loadAction = .load
            rp.depthAttachment.storeAction = .dontCare
        }
        if stencil {
            rp.stencilAttachment.texture = gBuffer.stencilTexture
            rp.stencilAttachment.loadAction = .load
            rp.stencilAttachment.storeAction = .store
        }
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
        
    func createTransformsBuffer(_ label: String, numElements: Int) -> MTLBuffer {
        let buffer = device.makeBuffer(length: numElements * MemoryLayout<Transform>.stride, options: [])
        buffer?.label = label
        return buffer!
    }
    
    public static func createSyncBuffer<T>(from data: T, device: MTLDevice) -> MTLBuffer? {
        return createBuffer(from: data, device: device, numCopies: Renderer.NumSyncBuffers)
    }
    
    public static func createSyncBuffer<T>(from array: [T], label: String, device: MTLDevice) -> MTLBuffer? {
        let numElements = array.count * Renderer.NumSyncBuffers
        guard let buffer = device.makeBuffer(length: numElements * MemoryLayout<T>.stride, options: []) else {
            NSLog("Failed to create MTLBuffer")
            return nil
        }
        buffer.label = label
        return buffer
    }
    
    public static func createBuffer<T>(from array: [T], device: MTLDevice) -> MTLBuffer? {
        let count = array.count
        guard let buffer = device.makeBuffer(length: count * MemoryLayout<T>.stride, options: []) else {
            NSLog("Failed to create MTLBuffer")
            return nil
        }
        let vb = buffer.contents().assumingMemoryBound(to: T.self)
        for i in 0..<count {
            vb[i] = array[i]
        }
        return buffer
    }
    
    public static func createBuffer<T>(from data: T, device: MTLDevice, numCopies: Int = 1) -> MTLBuffer? {
        guard let buffer = device.makeBuffer(length: numCopies * MemoryLayout<T>.stride, options: []) else {
            NSLog("Failed to create MTLBuffer")
            return nil
        }
        let vb = buffer.contents().assumingMemoryBound(to: T.self)
        for i in 0..<numCopies {
            vb[i] = data
        }
        return buffer
    }
}
