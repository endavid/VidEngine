//
//  ARPlugin.swift
//  VidFramework
//
//  Created by David Gavilan on 2018/08/21.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import MetalKit
import ARKit

class ARPlugin: GraphicPlugin {
    // Captured image texture cache
    var capturedImageTextureCache: CVMetalTextureCache!
    var imagePlaneVertexBuffer: MTLBuffer!
    var capturedImagePipelineState: MTLRenderPipelineState!
    var capturedImageDepthState: MTLDepthStencilState!
    var readCubemapState: MTLRenderPipelineState!
    fileprivate var lightProbes: [UUID: SHLight] = [:]
    
    var viewportSize = CGSize()
    // Vertex data for an image plane
    let kImagePlaneVertexData: [Float] = [
        -1.0, -1.0,  0.0, 1.0,
        1.0, -1.0,  1.0, 1.0,
        -1.0,  1.0,  0.0, 0.0,
        1.0,  1.0,  1.0, 0.0,
        ]
    
    override var label: String {
        get {
            return "AR"
        }
    }
    
    func queue(_ lightProbe: SHLight) {
        lightProbes[lightProbe.identifier] = lightProbe
    }
    func dequeue(_ lightProbe: SHLight) {
        lightProbes.removeValue(forKey: lightProbe.identifier)
    }
    func findProbe(identifier: UUID) -> SHLight? {
        return lightProbes[identifier]
    }
    
    fileprivate func createReadCubemapDescriptor(library: MTLLibrary, pixelFormat: MTLPixelFormat) -> MTLRenderPipelineDescriptor {
        let fn = library.makeFunction(name: "readCubemapSamples")!
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
        // Create captured image texture cache
        var textureCache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
        capturedImageTextureCache = textureCache
        // Create a vertex buffer with our image plane vertex data.
        let imagePlaneVertexDataCount = kImagePlaneVertexData.count * MemoryLayout<Float>.size
        imagePlaneVertexBuffer = device.makeBuffer(bytes: kImagePlaneVertexData, length: imagePlaneVertexDataCount, options: [])
        imagePlaneVertexBuffer.label = "ImagePlaneVertexBuffer"
        
        let capturedImageVertexFunction = library.makeFunction(name: "capturedImageVertexTransform")!
        let capturedImageFragmentFunction = library.makeFunction(name: "capturedImageFragmentShader")!
        
        // Create a vertex descriptor for our image plane vertex buffer
        let imagePlaneVertexDescriptor = MTLVertexDescriptor()
        
        // Positions.
        imagePlaneVertexDescriptor.attributes[0].format = .float2
        imagePlaneVertexDescriptor.attributes[0].offset = 0
        imagePlaneVertexDescriptor.attributes[0].bufferIndex = 0
        
        // Texture coordinates.
        imagePlaneVertexDescriptor.attributes[1].format = .float2
        imagePlaneVertexDescriptor.attributes[1].offset = 8
        imagePlaneVertexDescriptor.attributes[1].bufferIndex = 0
        
        // Buffer Layout
        imagePlaneVertexDescriptor.layouts[0].stride = 16
        imagePlaneVertexDescriptor.layouts[0].stepRate = 1
        imagePlaneVertexDescriptor.layouts[0].stepFunction = .perVertex
        
        // Create a pipeline state for rendering the captured image
        let capturedImagePipelineStateDescriptor = MTLRenderPipelineDescriptor()
        capturedImagePipelineStateDescriptor.label = "MyCapturedImagePipeline"
        capturedImagePipelineStateDescriptor.sampleCount = view.sampleCount
        capturedImagePipelineStateDescriptor.vertexFunction = capturedImageVertexFunction
        capturedImagePipelineStateDescriptor.fragmentFunction = capturedImageFragmentFunction
        capturedImagePipelineStateDescriptor.vertexDescriptor = imagePlaneVertexDescriptor
        capturedImagePipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        capturedImagePipelineStateDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
        capturedImagePipelineStateDescriptor.stencilAttachmentPixelFormat = view.depthStencilPixelFormat
        
        let readCubemapDesc = createReadCubemapDescriptor(library: library, pixelFormat: view.colorPixelFormat)
        
        do {
            try capturedImagePipelineState = device.makeRenderPipelineState(descriptor: capturedImagePipelineStateDescriptor)
            try readCubemapState = device.makeRenderPipelineState(descriptor: readCubemapDesc)
        } catch let error {
            logInitError(error)
        }
        
        let capturedImageDepthStateDescriptor = MTLDepthStencilDescriptor()
        capturedImageDepthStateDescriptor.depthCompareFunction = .always
        capturedImageDepthStateDescriptor.isDepthWriteEnabled = false
        capturedImageDepthState = device.makeDepthStencilState(descriptor: capturedImageDepthStateDescriptor)
    }
    
    override func draw(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer, camera: Camera) {
        guard let renderer = Renderer.shared else {
            return
        }
        if let frame = Renderer.shared.arSession?.currentFrame {
            updateCapturedImageTextures(frame: frame)
            if viewportSize.width != camera.bounds.width || viewportSize.height != camera.bounds.height {
                viewportSize = camera.bounds.size
                updateImagePlane(frame: frame, orientation: camera.orientation)
            }
        }
        let renderPassDescriptor = renderer.createRenderPassWithColorAttachmentTexture(drawable.texture, clear: true)
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        encoder.label = self.label
        updateLightProbes(encoder: encoder)
        drawCapturedImage(encoder: encoder)
        encoder.endEncoding()
        renderer.frameState.clearedDrawable = true
    }
    
    private func updateCapturedImageTextures(frame: ARFrame) {
        // Create two textures (Y and CbCr) from the provided frame's captured image
        let pixelBuffer = frame.capturedImage
        if (CVPixelBufferGetPlaneCount(pixelBuffer) < 2) {
            return
        }
        Renderer.shared.capturedImageTextureY = createTexture(fromPixelBuffer: pixelBuffer, pixelFormat:.r8Unorm, planeIndex:0)
        Renderer.shared.capturedImageTextureCbCr = createTexture(fromPixelBuffer: pixelBuffer, pixelFormat:.rg8Unorm, planeIndex:1)
    }
    
    private func createTexture(fromPixelBuffer pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int) -> CVMetalTexture? {
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        
        var texture: CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, capturedImageTextureCache, pixelBuffer, nil, pixelFormat, width, height, planeIndex, &texture)
        
        if status != kCVReturnSuccess {
            texture = nil
        }
        return texture
    }

    private func updateImagePlane(frame: ARFrame, orientation: UIInterfaceOrientation) {
        // Update the texture coordinates of our image plane to aspect fill the viewport
        let displayToCameraTransform = frame.displayTransform(for: orientation, viewportSize: viewportSize).inverted()
        
        let vertexData = imagePlaneVertexBuffer.contents().assumingMemoryBound(to: Float.self)
        for index in 0...3 {
            let textureCoordIndex = 4 * index + 2
            let textureCoord = CGPoint(x: CGFloat(kImagePlaneVertexData[textureCoordIndex]), y: CGFloat(kImagePlaneVertexData[textureCoordIndex + 1]))
            let transformedCoord = textureCoord.applying(displayToCameraTransform)
            vertexData[textureCoordIndex] = Float(transformedCoord.x)
            vertexData[textureCoordIndex + 1] = Float(transformedCoord.y)
        }
    }
    
    private func drawCapturedImage(encoder: MTLRenderCommandEncoder) {
        guard let textureY = Renderer.shared.capturedImageTextureY, let textureCbCr = Renderer.shared.capturedImageTextureCbCr else {
            return
        }
        
        // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool
        encoder.pushDebugGroup("DrawCapturedImage")
        
        // Set render command encoder state
        encoder.setCullMode(.none)
        encoder.setRenderPipelineState(capturedImagePipelineState)
        encoder.setDepthStencilState(capturedImageDepthState)
        
        // Set mesh's vertex buffers
        encoder.setVertexBuffer(imagePlaneVertexBuffer, offset: 0, index: 0)
        
        // Set any textures read/sampled from our render pipeline
        encoder.setFragmentTexture(CVMetalTextureGetTexture(textureY), index: 1)
        encoder.setFragmentTexture(CVMetalTextureGetTexture(textureCbCr), index: 2)
        
        // Draw each submesh of our mesh
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        encoder.popDebugGroup()
    }
    
    private func updateLightProbes(encoder: MTLRenderCommandEncoder) {
        for (_, probe) in lightProbes {
            if probe.phase == .readCubemap {
                encoder.pushDebugGroup("UpdateLightProbes")
                encoder.setRenderPipelineState(readCubemapState)
                probe.readCubemapSamples(encoder: encoder)
                encoder.popDebugGroup()
            } else {
                probe.update()
            }
        }
    }
}
