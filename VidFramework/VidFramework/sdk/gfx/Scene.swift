//
//  Scene.swift
//  VidEngine
//
//  Created by David Gavilan on 9/1/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Foundation
import UIKit
import simd

open class Scene {
    static let arPlanesPrimitiveName = "ARPlanes"
    public var primitives: [Primitive] = []
    public var groups2D: [Group2D] = []
    public var lights: [LightSource] = []
    /// When deserializing a Scene, this will have the initial
    /// camera position. The actual camera used in rendering
    /// is passed in the `update` function from the `VidController`.
    public var camera: Camera? = nil
    /// An object that it's placed where the camera view vector
    /// intersects with the scene
    public var cursor: Cursor3D?
    private var _debugARPlanes: Bool = false

    public var debugARPlanes: Bool {
        get {
            return _debugARPlanes
        }
        set {
            if _debugARPlanes != newValue {
                _debugARPlanes = newValue
                if let p = findPrimitive(by: Scene.arPlanesPrimitiveName) {
                    p.dequeue()
                    setupARPlanes(p)
                    if _debugARPlanes {
                        p.queue()
                    }
                }
            }
        }
    }
    
    func setupARPlanes(_ prim: Primitive) {
        if _debugARPlanes {
            prim.lightingType = .UnlitTransparent
            prim.material.diffuse = LinearRGBA(r: 1, g: 1, b: 1, a: 0.7)
            if let bundle = try? FrameworkBundle.mainBundle() {
                prim.setAlbedoTexture(resource: FrameworkBundle.measureGridImage, bundle: bundle, options: nil, addToCache: true) { (error) in
                    if let error = error {
                        NSLog("setupARPlanes: \(error.localizedDescription)")
                    }
                }
                prim.sampler = .pointWithWrap
            }
        } else {
            prim.lightingType = .LitOpaque
            prim.material.diffuse = .transparent
        }
    }
    
    /// Add & queue Primitive for rendering
    public func queue(_ primitive: Primitive, render: Bool = true) {
        let alreadyQueued = primitives.contains { $0 === primitive }
        if !alreadyQueued {
            primitives.append(primitive)
            if render {
                primitive.queue()
            }
        }
    }
    /// Add & queue LightSource for rendering
    public func queue(_ light: LightSource, render: Bool = true) {
        let alreadyQueued = lights.contains { $0 === light }
        if !alreadyQueued {
            lights.append(light)
            if render {
                light.queue()
            }
        }
    }
    
    /// Remove & dequeue Primitive
    public func dequeue(_ primitive: Primitive) {
        let index = primitives.firstIndex { $0 === primitive }
        if let i = index {
            primitives.remove(at: i)
            primitive.dequeue()
        }
    }
    /// Remove & dequeue LightSource
    public func dequeue(_ light: LightSource) {
        let index = lights.firstIndex { $0 === light }
        if let i = index {
            lights.remove(at: i)
            light.dequeue()
        }
    }

    /// Adds all elements to their respective rendering queues
    public func queueAll() {
        for p in primitives {
            p.queue()
        }
        for p in groups2D {
            p.queue()
        }
        for l in lights {
            l.queue()
        }
    }
    
    /// Removes all elements from the rendering queues.
    /// They will stop being rendered, but the elements aren't destroyed.
    public func dequeueAll() {
        for p in primitives {
            p.dequeue()
        }
        for p in groups2D {
            p.dequeue()
        }
        for l in lights {
            l.dequeue()
        }
    }
    
    /// Removes all elements from rendering and remove them from the scene.
    public func removeAll() {
        dequeueAll()
        primitives.removeAll()
        groups2D.removeAll()
        lights.removeAll()
    }
    
    open func update(_ currentTime: CFTimeInterval, camera: Camera) {
        let ray = camera.getGazeRay()
        updateCursor(gazeRay: ray, camera: camera)
    }
    
    public init() {
    }
    
    public func findPrimitive(by name: String) -> Primitive? {
        let index = primitives.firstIndex { $0.name == name }
        if let i = index {
            return primitives[i]
        }
        return nil
    }
    
    public func findPrimitiveInstance(by uuid: UUID) -> (Primitive, Int)? {
        let index = primitives.firstIndex { $0.uuidInstanceMap[uuid] != nil }
        if let i = index {
            let prim = primitives[i]
            let instanceIndex = prim.uuidInstanceMap[uuid]!
            return (prim, instanceIndex)
        }
        return nil
    }
    
    private func updateCursor(gazeRay: Ray, camera: Camera) {
        guard let c = cursor else {
            return
        }
        var prims: [Primitive] = []
        switch c.targetSurface {
        case .arPlanes:
            if let p = findPrimitive(by: Scene.arPlanesPrimitiveName) {
                prims = [p]
            }
        case .all:
            prims = self.primitives
        }
        var intersection: SurfaceIntersection?
        var distance = Float.greatestFiniteMagnitude
        for p in prims {
            if let si = p.getSurfaceIntersection(ray: gazeRay), si.distance < distance {
                distance = si.distance
                intersection = si
            }
        }
        if let si = intersection {
            // same orientation as the camera, but rotate it
            // so up vector points towards the surface normal
            let cameraUp = camera.getUpVector()
            let q = Quaternion.createRotation(start: cameraUp, end: si.normal)
            c.set(position: si.point, rotation: q * camera.transform.rotation)
            c.setIntersection(true)
        } else {
            // if the cursor is an XZ plane, this will make it
            // face the camera
            let q = Quaternion(AngleAxis(angle: .pi / 2, axis: simd_float3(1, 0, 0)))
            let p = gazeRay.travelDistance(d: c.defaultDistanceFromCamera)
            c.set(position: p, rotation: camera.transform.rotation * q)
            c.setIntersection(false)
        }
    }
}
