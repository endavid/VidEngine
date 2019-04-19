//
//  WorldTouch.swift
//  VidFramework
//
//  Created by David Gavilan on 2019/04/19.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import Metal

/// If you need to detect touches in your 3D scene, add this
/// to your scene
public class WorldTouch {
    public struct Point {
        public var worldPosition: Vec3
        public var objectId: UInt16
    }
    var touchUVs: [Vec2]
    var points: [Point]
    var locations: [CGPoint]
    let touchBuffer: MTLBuffer!
    let pointBuffer: MTLBuffer!
    var touchOffset = 0
    var pointOffset = 0
    
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
        let count = touchUVs.count
        var i = 0
        for t in touches {
            if i == count {
                break
            }
            let loc = t.location(in: view)
            let u = Float(loc.x / view.bounds.width)
            let v = Float(loc.y / view.bounds.height)
            touchUVs[i] = Vec2(u, v)
            locations[i] = loc
            i += 1
        }
    }
    
    public func getPoint(from touch: UITouch, in view: UIView) -> Point? {
        let loc = touch.location(in: view)
        var d = Float.greatestFiniteMagnitude
        var index = 0
        for i in 0..<locations.count {
            let dd = Distance(locations[i], loc)
            if dd < d {
                index = i
                d = dd
            }
        }
        let maxErrorDistance: Float = 1
        if d < maxErrorDistance {
            return points[index]
        }
        return nil
    }
    
    public init(maxTouchCount: Int) {
        touchUVs = [Vec2](repeating: Vec2.zero, count: maxTouchCount)
        points = [Point](repeating: Point(worldPosition: Vec3.zero, objectId: 0), count: maxTouchCount)
        locations = [CGPoint](repeating: CGPoint.zero, count: maxTouchCount)
        let device = Renderer.shared.device!
        touchBuffer = Renderer.createSyncBuffer(from: touchUVs, label: "touchBuffer", device: device)
        pointBuffer = Renderer.createSyncBuffer(from: points, label: "pointBuffer", device: device)
    }
    
    func updateBuffers(_ syncBufferIndex: Int) {
        copyTouchUVsToBuffer(syncBufferIndex)
        getPointsFromBuffers(syncBufferIndex)
    }
    func copyTouchUVsToBuffer(_ syncBufferIndex: Int) {
        let b = touchBuffer.contents()
        touchOffset = MemoryLayout<Vec2>.stride * touchUVs.count * syncBufferIndex
        let data = b.advanced(by: touchOffset).assumingMemoryBound(to: Float.self)
        memcpy(data, &touchUVs, MemoryLayout<Vec2>.stride * touchUVs.count)
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
        encoder.setVertexBuffer(touchBuffer, offset: touchOffset, index: 0)
        encoder.setVertexBuffer(pointBuffer, offset: pointOffset, index: 2)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: touchUVs.count)
    }
}
