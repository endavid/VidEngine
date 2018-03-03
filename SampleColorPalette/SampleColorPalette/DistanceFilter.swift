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
    var swapTexture: MTLTexture?
    var target: float4
    
    init?(device: MTLDevice, library: MTLLibrary, input: MTLTexture, target: float4) {
        self.target = target
        guard let vfn = library.makeFunction(name: "passThrough2DVertex"),
            let ffn = library.makeFunction(name: "passComputeDistance")
            else {
                NSLog("Failed to create shaders")
                return nil
        }
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vfn
        pipelineDescriptor.fragmentFunction = ffn
        pipelineDescriptor.colorAttachments[0].pixelFormat = input.pixelFormat
        pipelineDescriptor.sampleCount = input.sampleCount
        super.init(id: "DistanceFilter", device: device, descriptor: pipelineDescriptor)
        let pixelFormat = MTLPixelFormat.rgba16Unorm
        let distTexDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: input.width, height: input.height, mipmapped: false)
        distTexDescriptor.usage = [.shaderRead, .renderTarget]
        output = device.makeTexture(descriptor: distTexDescriptor)
        buffer = Renderer.createSyncBuffer(from: target, device: device)
    }
    
    override func postRender() {
        // swap inputs
        if let tmp = swapTexture {
            swapTexture = inputs.first
            inputs = [tmp]
        }
    }
    
    // this gets called when we need to update the buffers used by the GPU
    override func updateBuffers(_ syncBufferIndex: Int) {
        super.updateBuffers(syncBufferIndex)
        guard let contents = buffer?.contents() else {
            return
        }
        let data = contents.advanced(by: bufferOffset).assumingMemoryBound(to: float4.self)
        memcpy(data, &target, MemoryLayout<float4>.size)
    }
}
