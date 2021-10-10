//
//  Dots3D.swift
//  VidFramework
//
//  Created by David Gavilan on 2019/03/02.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import MetalKit

public class Dots3D {
    public struct Instance {
        public var transform: Transform
        public var dotSize: simd_float4
    }
    let vertexBuffer: MTLBuffer
    let colorBuffer: MTLBuffer
    let instanceBuffer: MTLBuffer
    let vertexCount: Int
    var bufferOffset = 0
    public var lightingType = LightingType.UnlitOpaque
    public var instances: [Instance]
    public var instanceCount: Int {
        get {
            return instances.count
        }
    }
    public func queue() {
        switch lightingType {
        case .UnlitOpaque:
            let p: UnlitOpaquePlugin? = Renderer.shared.getPlugin()
            p?.queue(self)
        default:
            NSLog("\(lightingType) unsupported for Dots3D")
        }
    }
    public func dequeue() {
        let p: UnlitOpaquePlugin? = Renderer.shared.getPlugin()
        p?.dequeue(self)
    }
    init(transform: Transform, dotSize: Float, vertexBuffer: MTLBuffer, colorBuffer: MTLBuffer, vertexCount: Int) {
        self.vertexBuffer = vertexBuffer
        self.colorBuffer = colorBuffer
        self.vertexCount = vertexCount
        let s = simd_float4(1, 1, 1, 1) * dotSize
        instances = [Instance(transform: transform, dotSize: s)]
        let device = Renderer.shared.device
        instanceBuffer = device!.makeBuffer(length: Renderer.NumSyncBuffers * MemoryLayout<Instance>.size, options: [])!
        instanceBuffer.label = "Dot3DInstances"
    }
    func draw(encoder: MTLRenderCommandEncoder) {
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexCount, instanceCount: instanceCount)
    }
    func updateBuffers(_ syncBufferIndex: Int) {
        let b = instanceBuffer.contents()
        bufferOffset = MemoryLayout<Instance>.size * instanceCount * syncBufferIndex
        let data = b.advanced(by: bufferOffset).assumingMemoryBound(to: Float.self)
        memcpy(data, &instances, MemoryLayout<Instance>.size * instanceCount)
    }
}
