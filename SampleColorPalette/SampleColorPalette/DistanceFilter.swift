//
//  DistanceFilter.swift
//  SampleColorPalette
//
//  Created by David Gavilan on 2018/03/03.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import VidFramework
import simd

class DistanceFilter: TextureFilter {
    var target: float4
    
    init?(device: MTLDevice, library: MTLLibrary, input: Texture, target: float4) {
        self.target = target
        guard let vfn = library.makeFunction(name: "passThrough2DVertex"),
            let ffn = library.makeFunction(name: "passComputeDistance")
            else {
                NSLog("Failed to create shaders")
                return nil
        }
        guard let inputTexture = input.mtlTexture else {
            return nil
        }
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vfn
        pipelineDescriptor.fragmentFunction = ffn
        pipelineDescriptor.colorAttachments[0].pixelFormat = inputTexture.pixelFormat
        pipelineDescriptor.sampleCount = inputTexture.sampleCount
        super.init(id: "DistanceFilter", device: device, descriptor: pipelineDescriptor)
        let pixelFormat = MTLPixelFormat.rgba16Unorm
        let distTexDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: inputTexture.width, height: inputTexture.height, mipmapped: false)
        distTexDescriptor.usage = [.shaderRead, .renderTarget]
        guard let outputTexture = device.makeTexture(descriptor: distTexDescriptor) else {
            return nil
        }
        output = Texture(id: "DistanceTex", mtlTexture: outputTexture)
        inputs = [input]
        fragmentBuffer = Renderer.createSyncBuffer(from: target, device: device)
    }
        
    // this gets called when we need to update the buffers used by the GPU
    override func updateBuffers(_ syncBufferIndex: Int) {
        super.updateBuffers(syncBufferIndex)
        guard let contents = fragmentBuffer?.contents() else {
            return
        }
        let data = contents.advanced(by: fragmentBufferOffset).assumingMemoryBound(to: float4.self)
        memcpy(data, &target, MemoryLayout<float4>.size)
    }
}
