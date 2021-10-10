//
//  LightSource.swift
//  VidEngine
//
//  Created by David Gavilan on 9/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import simd

public class LightSource {
    public var name: String = ""
    
    public func queue() {
        if let p: DeferredLightingPlugin = Renderer.shared?.getPlugin() {
            p.queue(self)
        }
    }
    
    public func dequeue() {
        if let p: DeferredLightingPlugin = Renderer.shared?.getPlugin() {
            p.dequeue(self)
        }
    }
}

public class DirectionalLight: LightSource {
    public struct Instance {
        public var color: LinearRGBA
        public var direction: simd_float4
    }
    public var instances: [Instance]
    let uniformBuffer: MTLBuffer!
    var bufferOffset = 0
    
    public var instanceCount: Int {
        get {
            return instances.count
        }
    }
    public var direction: simd_float3 {
        get {
            let d = instances[0].direction
            return simd_float3(d.x, d.y, d.z)
        }
        set {
            let w = instances[0].direction.w
            let d = simd_float4(newValue.x, newValue.y, newValue.z, w)
            for i in 0..<instanceCount {
                instances[i].direction = d
            }
        }
    }
    public var color: LinearRGBA {
        get {
            return instances[0].color
        }
        set {
            for i in 0..<instanceCount {
                instances[i].color = newValue
            }
        }
    }
    
    public init(instanceCount: Int) {
        assert(instanceCount > 0, "The number of instances should be >0")
        assert(Renderer.shared != nil, "The Renderer hasn't been created")
        assert(Renderer.shared.device != nil, "Missing device")
        self.instances = [Instance](repeating: Instance(color: LinearRGBA(r: 1, g: 1, b: 1, a: 1), direction: simd_float4(0,1,0,0)), count: instanceCount)
        self.uniformBuffer = Renderer.createSyncBuffer(from: instances, label: "directionalLights", device: Renderer.shared.device)
    }
    
    func updateBuffers(_ syncBufferIndex: Int) {
        bufferOffset = MemoryLayout<Instance>.size * instances.count * syncBufferIndex
        let uniformB = uniformBuffer.contents()
        let uniformData = uniformB.advanced(by: bufferOffset).assumingMemoryBound(to: Float.self)
        memcpy(uniformData, &instances, MemoryLayout<Instance>.size * instances.count)
    }
}
