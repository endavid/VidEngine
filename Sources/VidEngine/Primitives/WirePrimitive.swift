//
//  WirePrimitive.swift
//  VidFramework
//
//  Created by David Gavilan on 2019/03/03.
//

import MetalKit

public class WirePrimitive {
    public struct Instance {
        public var transform: Transform
        public var color: LinearRGBA
    }
    var vertexBuffer: MTLBuffer?
    var instanceBuffer: MTLBuffer?
    let lines: [Line]
    var bufferOffset = 0
    public var instances: [Instance]
    public var lightingType = LightingType.UnlitOpaque

    public var instanceCount: Int {
        get {
            return instances.count
        }
    }
    public var lineCount: Int {
        get {
            return lines.count
        }
    }
    // convenience getters & setters for the case we have only 1 instance
    public var transform: Transform {
        get {
            return instances[0].transform
        }
        set {
            for i in 0..<instanceCount {
                instances[i].transform = newValue
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
    public func queue(renderer: Renderer) {
        initBuffers(renderer)
        switch lightingType {
        case .UnlitOpaque:
            let p: UnlitOpaquePlugin? = renderer.getPlugin()
            p?.queue(self)
        default:
            NSLog("\(lightingType) unsupported for WirePrimitive")
        }
    }
    public func dequeue(renderer: Renderer) {
        let p: UnlitOpaquePlugin? = renderer.getPlugin()
        p?.dequeue(self)
    }
    
    init(instanceCount: Int, lines: [Line]) {
        self.lines = lines
        let instance = Instance(transform: Transform(), color: LinearRGBA(.white))
        instances = [Instance](repeating: instance, count: instanceCount)

    }
    
    func initBuffers(_ renderer: Renderer) {
        if instanceBuffer == nil {
            instanceBuffer = renderer.device.makeBuffer(length: Renderer.numSyncBuffers * MemoryLayout<Instance>.size * instanceCount, options: [])
            instanceBuffer?.label = "WirePrimitiveInstances"
        }
        if vertexBuffer == nil {
            vertexBuffer = renderer.device.makeBuffer(length: lines.count * MemoryLayout<Line>.size, options: [])
            if let vb = vertexBuffer {
                let b = vb.contents()
                let data = b.assumingMemoryBound(to: Line.self)
                memcpy(data, lines, MemoryLayout<Line>.size * lines.count)
            }
        }
    }
    
    func draw(encoder: MTLRenderCommandEncoder) {
        encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: lineCount * 2, instanceCount: instanceCount)
    }
    
    func updateBuffers(_ syncBufferIndex: Int) {
        guard let instanceBuffer = self.instanceBuffer else {
            return
        }
        let size = MemoryLayout<Instance>.size * instanceCount
        bufferOffset = size * syncBufferIndex
        let b = instanceBuffer.contents()
        let data = b.advanced(by: bufferOffset).assumingMemoryBound(to: Instance.self)
        memcpy(data, instances, size)
    }
}
