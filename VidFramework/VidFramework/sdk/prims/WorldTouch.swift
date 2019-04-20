//
//  WorldTouch.swift
//  VidFramework
//
//  Created by David Gavilan on 2019/04/19.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import Metal

extension UITouch {
    func uv(in view: UIView) -> Vec2 {
        let loc = location(in: view)
        let u = Float(loc.x / view.bounds.width)
        let v = Float(loc.y / view.bounds.height)
        return Vec2(u, v)
    }
}

struct TouchData {
    static let zero = TouchData(uv: .zero, hash: 0)
    public var uv: Vec2
    public var hash: UInt32
}

/// If you need to detect touches in your 3D scene, add this
/// to your scene
public class WorldTouch {
    public struct Point {
        public var worldPosition: Vec3
        public var hash: UInt32
        public var objectId: UInt16
    }
    enum Phase {
        case
        set,
        collecting,
        stopped
    }
    var touchData: [TouchData]
    var points: [Point]
    let touchCount: Int
    let touchBuffer: MTLBuffer!
    let pointBuffer: MTLBuffer!
    var touchOffset = 0
    var pointOffset = 0
    private var _phase = Phase.stopped
    
    var phase: Phase {
        get {
            return _phase
        }
    }
    
    public func queue() {
        if let p: TouchPlugin? = Renderer.shared.getPlugin() {
            p?.queue(self)
        }
    }
    public func dequeue() {
        if let p: TouchPlugin? = Renderer.shared.getPlugin() {
            p?.dequeue(self)
        }
    }
    
    public func setTouches(_ touches: Set<UITouch>, in view: UIView) {
        var i = 0
        for t in touches {
            if i == touchCount {
                break
            }
            let uv = t.uv(in: view)
            let hash = UInt32(truncatingIfNeeded: t.hashValue)
            touchData[i] = TouchData(uv: uv, hash: hash)
            i += 1
        }
        if _phase == .stopped {
            _phase = .set
        }
    }
    
    public func clearTouches() {
        _phase = .stopped
        points = [Point](repeating: Point(worldPosition: Vec3.zero, hash: 0, objectId: 0), count: touchCount)
        touchData = [TouchData](repeating: .zero, count: touchCount)
    }
    
    public func getPoint(from touch: UITouch, in view: UIView) -> Point? {
        if _phase != .collecting {
            return nil
        }
        let hash = UInt32(truncatingIfNeeded: touch.hashValue)
        for i in 0..<touchCount {
            if points[i].hash == hash {
                // print("getPoint: \(points[i].objectId) \(hash)")
                return points[i]
            }
        }
        return nil
    }
    
    public init(maxTouchCount: Int) {
        touchCount = maxTouchCount
        touchData = [TouchData](repeating: .zero, count: touchCount)
        points = [Point](repeating: Point(worldPosition: Vec3.zero, hash: 0, objectId: 0), count: maxTouchCount)
        let device = Renderer.shared.device!
        touchBuffer = Renderer.createSyncBuffer(from: touchData, label: "touchBuffer", device: device)
        pointBuffer = Renderer.createSyncBuffer(from: points, label: "pointBuffer", device: device)
    }
    
    func updateBuffers(_ syncBufferIndex: Int) {
        if _phase == .stopped {
            return
        }
        copyTouchDataToBuffer(syncBufferIndex)
        getPointsFromBuffers(syncBufferIndex)
        _phase = .collecting
    }
    func copyTouchDataToBuffer(_ syncBufferIndex: Int) {
        let b = touchBuffer.contents()
        touchOffset = MemoryLayout<TouchData>.stride * touchCount * syncBufferIndex
        let data = b.advanced(by: touchOffset).assumingMemoryBound(to: TouchData.self)
        memcpy(data, &touchData, MemoryLayout<TouchData>.stride * touchCount)
    }
    func getPointsFromBuffers(_ syncBufferIndex: Int) {
        // offset for writing
        pointOffset = MemoryLayout<Point>.stride * points.count * syncBufferIndex
        // offset for reading
        let readIndex = (syncBufferIndex + Renderer.NumSyncBuffers - 1) % Renderer.NumSyncBuffers
        let readOffset = MemoryLayout<Point>.stride * points.count * readIndex
        let b = pointBuffer.contents()
        let data = b.advanced(by: readOffset).assumingMemoryBound(to: Point.self)
        memcpy(&points, data, MemoryLayout<Point>.stride * points.count)
    }
    
    func readSamples(encoder: MTLRenderCommandEncoder) {
        if _phase != .collecting {
            return
        }
        encoder.setVertexBuffer(touchBuffer, offset: touchOffset, index: 0)
        encoder.setVertexBuffer(pointBuffer, offset: pointOffset, index: 2)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: touchCount)
    }
}
