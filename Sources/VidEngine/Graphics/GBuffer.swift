//
//  GBuffer.swift
//  VidEngine
//
//  Created by David Gavilan on 9/10/16.
//

import Metal
import MetalKit

enum LightMask: UInt32 {
    case none = 0x00
    case ambient = 0x08
    case light = 0x80
    case all = 0x88
}

struct GBuffer {
    let width : Int
    let height : Int
    let depthTexture: MTLTexture
    let stencilTexture: MTLTexture
    let albedoTexture: MTLTexture
    let normalTexture: MTLTexture
    /// Buffer where we store the object IDs
    let objectTexture: MTLTexture
    /// light accumulation buffer; cleared and reused for transparency
    let lightTexture: MTLTexture
    /// For Order-Independent Transparency
    let revealTexture: MTLTexture
    /// Intermediate buffer where the output of shading is stored
    let shadedTexture: MTLTexture
    
    init(device: MTLDevice, size: CGSize) {
        width = Int(size.width)
        height = Int(size.height)
        let depthDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: width, height: height, mipmapped: false)
        depthDesc.usage = [.renderTarget, .shaderRead]
        let stencilDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .stencil8, width: width, height: height, mipmapped: false)
        stencilDesc.usage = .renderTarget
        let albedoDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm_srgb, width: width, height: height, mipmapped: false)
        albedoDesc.usage = [.renderTarget, .shaderRead]
        let normalDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Snorm, width: width, height: height, mipmapped: false)
        normalDesc.usage = [.renderTarget, .shaderRead]
        let objectDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r16Uint, width: width, height: height, mipmapped: false)
        objectDesc.usage = [.renderTarget, .shaderRead]
        let lightDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float, width: width, height: height, mipmapped: false)
        lightDesc.usage = [.renderTarget, .shaderRead]
        let revealDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r16Float, width: width, height: height, mipmapped: false)
        revealDesc.usage = [.renderTarget, .shaderRead]
        let shadedDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm_srgb, width: width, height: height, mipmapped: false)
        shadedDesc.usage = [.renderTarget, .shaderRead]
        depthTexture = device.makeTexture(descriptor: depthDesc)!
        depthTexture.label = "GBuffer:Depth"
        stencilTexture = device.makeTexture(descriptor: stencilDesc)!
        stencilTexture.label = "GBuffer:Stencil"
        albedoTexture = device.makeTexture(descriptor: albedoDesc)!
        albedoTexture.label = "GBuffer:Albedo"
        normalTexture = device.makeTexture(descriptor: normalDesc)!
        normalTexture.label = "GBuffer:Normal"
        objectTexture = device.makeTexture(descriptor: objectDesc)!
        objectTexture.label = "GBuffer:ObjectId"
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
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = albedoTexture.pixelFormat
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = false
        pipelineStateDescriptor.colorAttachments[1].pixelFormat = normalTexture.pixelFormat
        pipelineStateDescriptor.colorAttachments[1].isBlendingEnabled = false
        pipelineStateDescriptor.colorAttachments[2].pixelFormat = objectTexture.pixelFormat
        pipelineStateDescriptor.colorAttachments[2].isBlendingEnabled = false
        pipelineStateDescriptor.sampleCount = albedoTexture.sampleCount
        pipelineStateDescriptor.depthAttachmentPixelFormat = depthTexture.pixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = stencilTexture.pixelFormat
        return pipelineStateDescriptor
    }
    
    func createUnlitPipelineDescriptor(device: MTLDevice, library: MTLLibrary, isBlending: Bool, fragmentShader: String? = nil, vertexShader: String? = nil) -> MTLRenderPipelineDescriptor {
        let fragmentProgram = library.makeFunction(name: fragmentShader ?? "texturedFragment")!
        let vertexProgram = library.makeFunction(name: vertexShader ?? "passGeometry")!
        
        let vertexDesc = TexturedVertex.createVertexDescriptor()
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.vertexDescriptor = vertexDesc
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = shadedTexture.pixelFormat
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = isBlending
        if isBlending {
            pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
            pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
            pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
            pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
            
        }
        pipelineStateDescriptor.sampleCount = shadedTexture.sampleCount
        pipelineStateDescriptor.depthAttachmentPixelFormat = depthTexture.pixelFormat
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
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        pipelineStateDescriptor.colorAttachments[1].pixelFormat = self.revealTexture.pixelFormat
        pipelineStateDescriptor.colorAttachments[1].isBlendingEnabled = true
        pipelineStateDescriptor.colorAttachments[1].rgbBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[1].alphaBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[1].sourceRGBBlendFactor = .zero
        pipelineStateDescriptor.colorAttachments[1].sourceAlphaBlendFactor = .zero
        pipelineStateDescriptor.colorAttachments[1].destinationRGBBlendFactor = .oneMinusSourceColor
        pipelineStateDescriptor.colorAttachments[1].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipelineStateDescriptor.sampleCount = self.lightTexture.sampleCount
        pipelineStateDescriptor.depthAttachmentPixelFormat = depthTexture.pixelFormat
        return pipelineStateDescriptor
    }
    
    func createDepthDescriptor() -> MTLDepthStencilDescriptor {
        let desc = MTLDepthStencilDescriptor()
        desc.isDepthWriteEnabled = true
        desc.depthCompareFunction = .less
        return desc
    }
    
    func createDepthStencilDescriptorForAmbientLightGeometry() -> MTLDepthStencilDescriptor {
        let desc = MTLDepthStencilDescriptor()
        desc.isDepthWriteEnabled = false
        desc.depthCompareFunction = .less
        let bf = MTLStencilDescriptor()
        bf.stencilFailureOperation = .keep
        bf.depthFailureOperation = .replace
        bf.depthStencilPassOperation = .keep
        bf.stencilCompareFunction = .notEqual
        bf.readMask = LightMask.ambient.rawValue
        bf.writeMask = LightMask.light.rawValue
        let ff = MTLStencilDescriptor()
        ff.stencilFailureOperation = .keep
        ff.depthFailureOperation = .zero
        ff.depthStencilPassOperation = .keep
        ff.stencilCompareFunction = .notEqual
        ff.readMask = LightMask.light.rawValue
        ff.writeMask = LightMask.light.rawValue
        desc.backFaceStencil = bf
        desc.frontFaceStencil = ff
        return desc
    }
    
    func createDepthStencilDescriptorForAmbientLight() -> MTLDepthStencilDescriptor {
        let desc = MTLDepthStencilDescriptor()
        let ff = MTLStencilDescriptor()
        ff.stencilFailureOperation = .keep
        ff.depthFailureOperation = .keep
        ff.depthStencilPassOperation = .replace
        ff.stencilCompareFunction = .notEqual
        ff.readMask = LightMask.light.rawValue
        ff.writeMask = LightMask.all.rawValue
        desc.frontFaceStencil = ff
        desc.backFaceStencil = ff
        return desc
    }
    
}
