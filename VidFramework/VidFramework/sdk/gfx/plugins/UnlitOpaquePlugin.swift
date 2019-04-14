//
//  UnlitOpaquePlugin.swift
//  VidFramework
//
//  Created by David Gavilan on 2019/02/24.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

class UnlitOpaquePlugin: PrimitivePlugin {
    fileprivate var envSpheres: [EnvironmentSphere] = []
    fileprivate var envSpherePipelineState: MTLRenderPipelineState! = nil
    fileprivate var _whiteCubemap : MTLTexture! = nil

    override var label: String {
        get {
            return "UnlitPrimitives"
        }
    }
    override var isEmpty: Bool {
        get {
            return super.isEmpty && envSpheres.isEmpty
        }
    }
    override func queue(_ primitive: Primitive) {
        if let sphere = primitive as? EnvironmentSphere {
            let alreadyQueued = envSpheres.contains { $0 === sphere }
            if !alreadyQueued {
                envSpheres.append(sphere)
            }
        } else {
            super.queue(primitive)
        }
    }
    override func dequeue(_ primitive: Primitive) {
        if let sphere = primitive as? EnvironmentSphere {
            let index = envSpheres.firstIndex { $0 === sphere }
            if let i = index {
                envSpheres.remove(at: i)
            }
        } else {
            super.dequeue(primitive)
        }
    }
    override func createPipelineDescriptor(device: MTLDevice, library: MTLLibrary, gBuffer: GBuffer) -> MTLRenderPipelineDescriptor {
        return gBuffer.createUnlitPipelineDescriptor(device: device, library: library, isBlending: false)
    }
    override func createDotsDescriptor(device: MTLDevice, library: MTLLibrary, gBuffer: GBuffer) -> MTLRenderPipelineDescriptor {
        return gBuffer.createUnlitPipelineDescriptor(device: device, library: library, isBlending: false, fragmentShader: "dotsFragment", vertexShader: "dotsVertex")
    }
    override func createWiresDescriptor(device: MTLDevice, library: MTLLibrary, gBuffer: GBuffer) -> MTLRenderPipelineDescriptor? {
        return gBuffer.createUnlitPipelineDescriptor(device: device, library: library, isBlending: false, fragmentShader: "wiresFragment", vertexShader: "wiresVertex")
    }
    func createEnvSphereDescriptor(device: MTLDevice, library: MTLLibrary, gBuffer: GBuffer) -> MTLRenderPipelineDescriptor {
        return gBuffer.createUnlitPipelineDescriptor(device: device, library: library, isBlending: false, fragmentShader: "passSkyboxFragment", vertexShader: "passSkyboxGeometry")
    }
    override func createEncoder(commandBuffer: MTLCommandBuffer) -> MTLRenderCommandEncoder? {
        let renderer = Renderer.shared!
        let clear = !renderer.frameState.clearedBackbuffer
        let renderPassDescriptor = renderer.createUnlitRenderPass(clear: clear)
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        if let e = encoder {
            e.label = self.label
            renderer.frameState.clearedBackbuffer = true
        }
        return encoder
    }
    override init(device: MTLDevice, library: MTLLibrary, view: MTKView, gBuffer: GBuffer) {
        super.init(device: device, library: library, view: view, gBuffer: gBuffer)
        let envSpherePipelineDesc = createEnvSphereDescriptor(device: device, library: library, gBuffer: gBuffer)
        do {
            try envSpherePipelineState = device.makeRenderPipelineState(descriptor: envSpherePipelineDesc)
        } catch let error {
            NSLog("Failed to create pipeline state, error \(error)")
        }
        _whiteCubemap = TextureUtils.createWhiteCubemap(device: device)
    }
    override func draw(encoder: MTLRenderCommandEncoder) {
        super.draw(encoder: encoder)
        drawEnvSpheres(encoder: encoder)
    }
    func drawEnvSpheres(encoder: MTLRenderCommandEncoder) {
        if envSpheres.isEmpty {
            return
        }
        encoder.pushDebugGroup(self.label+":envSpheres")
        encoder.setRenderPipelineState(envSpherePipelineState)
        encoder.setDepthStencilState(depthState)
        encoder.setFrontFacing(.counterClockwise)
        encoder.setCullMode(.back)
        Renderer.shared.setGraphicsDataBuffer(encoder, atIndex: 1)
        PrimitivePlugin.drawAll(encoder: encoder, primitives: envSpheres, defaultTexture: _whiteCubemap)
        encoder.popDebugGroup()
    }
    override func updateBuffers(_ syncBufferIndex: Int, camera: Camera) {
        super.updateBuffers(syncBufferIndex, camera: camera)
        for p in envSpheres {
            p.updateBuffers(syncBufferIndex)
        }
    }
}
