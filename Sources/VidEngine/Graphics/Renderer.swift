//
//  File.swift
//  
//
//  Created by David Gavilan Ruiz on 01/03/2024.
//

import MetalKit
import simd
#if canImport(ARKit)
import ARKit
#endif

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
    var camera = Camera()
    var graphicsData = GraphicsData()
    var clearColor = MTLClearColorMake(38/255, 35/255, 35/255, 1.0)
    var frameState = FrameState()
    var arSession: ARSession?
    // These textures are for capturing the camera feed in an AR app
    var capturedImageTextureY: CVMetalTexture?
    var capturedImageTextureCbCr: CVMetalTexture?
    
    private var _graphicsDataBuffer: MTLBuffer! = nil
    private var _syncBufferIndex = 0
    private var _gBuffer: GBuffer
    private var _whiteTexture: MTLTexture! = nil
    private var _clearTexture: MTLTexture! = nil
    private lazy var _fullScreenQuad : FullScreenQuad = {
        return FullScreenQuad(renderer: self)
    }()
    // Instead of a Render Graph, we have an ordered list of plugins for now
    private var plugins : [GraphicPlugin] = []
    
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
            return MemoryLayout<GraphicsData>.size * _syncBufferIndex
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
        encoder.setVertexBuffer(_graphicsDataBuffer, offset: uniformBufferOffset, index: atIndex)
    }
    
    init(view: MTKView, doAR: Bool = false) throws {
        guard let device = view.device else {
            throw RenderError.missingDevice
        }
        self.device = device
        _whiteTexture = TextureUtils.createTexture(device: device, color: 0xffffffff)
        _clearTexture = TextureUtils.createTexture(device: device, color: 0x0)
        _graphicsDataBuffer = device.makeBuffer(length: MemoryLayout<GraphicsData>.size * Renderer.numSyncBuffers, options: [])
        _graphicsDataBuffer.label = "GraphicsData"
        // dummy buffer so _gBuffer is never null
        _gBuffer = GBuffer(device: device, size: CGSize(width: 1, height: 1))
        textureSamplers = TextureSamplers(device: device)
        self.initGraphicPlugins(view, doAR: doAR)
        if doAR {
            arSession = ARSession()
        }
    }
    
    func makeVidLibrary() -> MTLLibrary? {
        guard let url = VidBundle.metallib else {
            NSLog("Missing default.metallib in bundle")
            return nil
        }
        do {
            let library = try device.makeLibrary(URL: url)
            return library
        } catch {
            NSLog("makeLibrary failed for default.metallib")
            return nil
        }
    }
    
    private func initGraphicPlugins(_ view: MTKView, doAR: Bool) {
        guard let library = makeVidLibrary() else {
            return
        }
        // order is important!
        //plugins.append(FilterPlugin())
        if (doAR) {
        //    plugins.append(ARPlugin(device: device, library: library, view: view))
        }
        plugins.append(LitOpaquePlugin(device: device, library: library, view: view, gBuffer: gBuffer))
        //plugins.append(DeferredLightingPlugin(device: device, library: library, view: view, gBuffer: gBuffer))
        //plugins.append(DeferredShadingPlugin(device: device, library: library, view: view, gBuffer: gBuffer))
        plugins.append(UnlitOpaquePlugin(device: device, library: library, view: view, gBuffer: gBuffer))
        plugins.append(UnlitTransparencyPlugin(device: device, library: library, view: view, gBuffer: gBuffer))
        //plugins.append(DownsamplePlugin(device: device, library: library, view: view, gBuffer: gBuffer, downscaleLevel: 2))
        plugins.append(PostEffectPlugin(device: device, library: library, view: view, blend: doAR))
        //plugins.append(TouchPlugin(device: device, library: library, view: view))
        //plugins.append(RainPlugin(device: device, library: library, view: view))
        //plugins.append(Primitive2DPlugin(device: device, library: library, view: view))
    }
    
    func updateBuffers() {
        let uniformB = _graphicsDataBuffer.contents()
        let uniformData = uniformB.advanced(by: MemoryLayout<GraphicsData>.size * _syncBufferIndex).assumingMemoryBound(to: Float.self)
        graphicsData.projectionMatrix = camera.projection
        graphicsData.viewMatrix = camera.viewMatrix
        memcpy(uniformData, &graphicsData, MemoryLayout<GraphicsData>.size)
        for p in plugins {
            p.updateBuffers(_syncBufferIndex, camera: camera)
        }
    }
    
    func draw(_ view: MTKView, commandBuffer: MTLCommandBuffer) {
        guard let currentDrawable = view.currentDrawable else {
            return
        }
        let w = _gBuffer.width
        let h = _gBuffer.height
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
            plugin.draw(renderer: self, drawable: currentDrawable, commandBuffer: commandBuffer, camera: camera)
        }
        commandBuffer.present(currentDrawable)
        // syncBufferIndex matches the current semaphore controled frame index to ensure writing occurs at the correct region in the vertex buffer
        _syncBufferIndex = (_syncBufferIndex + 1) % Renderer.numSyncBuffers
        commandBuffer.commit()
    }
    
    // MARK: Render passes
    
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
    
    func getTextureAsImage(_ id: GBufferTexture) -> CGImage? {
        // On Intel Macs, the default storageMode is managed, so we need to blit the texture.
        // On ARM Macs, it's shared, so we can write the texture straight away
        switch id {
        case .shaded:
            return CGImageFrom(texture: _gBuffer.shadedTexture, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)
        default:
            return nil
        }
    }
}
