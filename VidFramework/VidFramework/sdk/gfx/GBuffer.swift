//
//  GBuffer.swift
//  VidEngine
//
//  Created by David Gavilan on 9/10/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit


struct GBuffer {
    let width : Int
    let height : Int
    let depthTexture : MTLTexture
    let albedoTexture : MTLTexture
    let normalTexture : MTLTexture
    let lightTexture : MTLTexture // light accumulation buffer; cleared and reused for transparency
    let revealTexture: MTLTexture // for OIT
    let shadedTexture : MTLTexture // intermediate buffer
    
    init(device: MTLDevice, size: CGSize) {
        width = Int(size.width)
        height = Int(size.height)
        let depthDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: width, height: height, mipmapped: false)
        depthDesc.usage = .renderTarget
        let albedoDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm_srgb, width: width, height: height, mipmapped: false)
        albedoDesc.usage = [.renderTarget, .shaderRead]
        let normalDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Snorm, width: width, height: height, mipmapped: false)
        normalDesc.usage = [.renderTarget, .shaderRead]
        let lightDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float, width: width, height: height, mipmapped: false)
        lightDesc.usage = [.renderTarget, .shaderRead]
        let revealDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r16Float, width: width, height: height, mipmapped: false)
        revealDesc.usage = [.renderTarget, .shaderRead]
        let shadedDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm_srgb, width: width, height: height, mipmapped: false)
        shadedDesc.usage = [.renderTarget, .shaderRead]
        depthTexture = device.makeTexture(descriptor: depthDesc)!
        depthTexture.label = "GBuffer:Depth"
        albedoTexture = device.makeTexture(descriptor: albedoDesc)!
        albedoTexture.label = "GBuffer:Albedo"
        normalTexture = device.makeTexture(descriptor: normalDesc)!
        normalTexture.label = "GBuffer:Normal"
        lightTexture = device.makeTexture(descriptor: lightDesc)!
        lightTexture.label = "LightAccumulation"
        revealTexture = device.makeTexture(descriptor: revealDesc)!
        revealTexture.label = "Reveal"
        shadedTexture = device.makeTexture(descriptor: shadedDesc)!
        shadedTexture.label = "Shading Output"
    }
    
    func createPipelineDescriptor(device: MTLDevice, library: MTLLibrary, fragmentShader: String? = nil) -> MTLRenderPipelineDescriptor {
        let fragmentProgram = library.makeFunction(name: fragmentShader ?? "passLightFragment")!
        let vertexProgram = library.makeFunction(name: "passLightGeometry")!
        
        let vertexDesc = TexturedVertex.createVertexDescriptor()
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.vertexDescriptor = vertexDesc
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.albedoTexture.pixelFormat
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = false
        pipelineStateDescriptor.colorAttachments[1].pixelFormat = self.normalTexture.pixelFormat
        pipelineStateDescriptor.colorAttachments[1].isBlendingEnabled = false
        pipelineStateDescriptor.sampleCount = self.albedoTexture.sampleCount
        pipelineStateDescriptor.depthAttachmentPixelFormat = self.depthTexture.pixelFormat
        return pipelineStateDescriptor
    }
    
    func createUnlitPipelineDescriptor(device: MTLDevice, library: MTLLibrary, isBlending: Bool, fragmentShader: String? = nil, vertexShader: String? = nil) -> MTLRenderPipelineDescriptor {
        let fragmentProgram = library.makeFunction(name: fragmentShader ?? "passThroughTexturedFragment")!
        let vertexProgram = library.makeFunction(name: vertexShader ?? "passGeometry")!
        
        let vertexDesc = TexturedVertex.createVertexDescriptor()
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.vertexDescriptor = vertexDesc
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.shadedTexture.pixelFormat
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = isBlending
        if isBlending {
            pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
            pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
            pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
            pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
            
        }
        pipelineStateDescriptor.sampleCount = self.shadedTexture.sampleCount
        pipelineStateDescriptor.depthAttachmentPixelFormat = self.depthTexture.pixelFormat
        return pipelineStateDescriptor
    }
    
    func createOITPipelineDescriptor(device: MTLDevice, library: MTLLibrary, fragmentShader: String? = nil) -> MTLRenderPipelineDescriptor {
        let fragmentProgram = library.makeFunction(name: fragmentShader ?? "passFragmentOIT")!
        let vertexProgram = library.makeFunction(name: "passGeometryOIT")!
        
        let vertexDesc = TexturedVertex.createVertexDescriptor()
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.vertexDescriptor = vertexDesc
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.lightTexture.pixelFormat
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .zero
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipelineStateDescriptor.colorAttachments[1].pixelFormat = self.revealTexture.pixelFormat
        pipelineStateDescriptor.colorAttachments[1].isBlendingEnabled = true
        pipelineStateDescriptor.colorAttachments[1].rgbBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[1].alphaBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[1].sourceRGBBlendFactor = .one
        pipelineStateDescriptor.colorAttachments[1].sourceAlphaBlendFactor = .zero
        pipelineStateDescriptor.colorAttachments[1].destinationRGBBlendFactor = .one
        pipelineStateDescriptor.colorAttachments[1].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipelineStateDescriptor.sampleCount = self.lightTexture.sampleCount
        pipelineStateDescriptor.depthAttachmentPixelFormat = self.depthTexture.pixelFormat
        return pipelineStateDescriptor
    }
    
    func createDepthStencilDescriptor() -> MTLDepthStencilDescriptor {
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.isDepthWriteEnabled = true
        depthDescriptor.depthCompareFunction = .less
        return depthDescriptor
    }
}
