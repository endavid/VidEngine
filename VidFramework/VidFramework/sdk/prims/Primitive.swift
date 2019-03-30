//
//  Primitive.swift
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

/// A `Primitive` is an object that requires 3D rendering to be displayed.
/// All primitives allow instancing.
public class Primitive {
    struct Mesh {
        let numIndices: Int
        let indexBuffer: MTLBuffer
        // this is not in the Material because it can only be set for ALL instances
        var albedoTexture: MTLTexture?
        var sampler: TextureSamplers.SamplerType
    }
    public struct Instance {
        public var transform: Transform
        public var material: Material
    }
    // To implement instanced rendering: http://metalbyexample.com/instanced-rendering/
    var vertexBuffer : MTLBuffer!
    public var name: String = ""
    public var instances: [Instance]
    let uniformBuffer: MTLBuffer!
    public var lightingType: LightingType = .LitOpaque
    var submeshes: [Mesh] = []
    var uuidInstanceMap: [UUID: Int] = [:]
    var bufferOffset = 0
    
    public var instanceCount: Int {
        get {
            return instances.count
        }
    }
    // convenience getter & setter for the case we have only 1 instance
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
    // convenience getter & setter for the case we have only 1 instance
    public var material: Material {
        get {
            return instances[0].material
        }
        set {
            for i in 0..<instanceCount {
                instances[i].material = newValue
            }
        }
    }
    
    /// Set the texture of all the submeshes. If you need to set up a different texture per submesh, please use the submeshes field.
    public var albedoTexture: MTLTexture? {
        get {
            return submeshes[0].albedoTexture
        }
        set {
            submeshes[0].albedoTexture = newValue
        }
    }
    
    public var sampler: TextureSamplers.SamplerType {
        get {
            return submeshes[0].sampler
        }
        set {
            submeshes[0].sampler = newValue
        }
    }
    
    #if DEBUG
    deinit {
        // Just making sure that we clean up properly!
        print("Removing Primitive \(name)")
    }
    #endif
    
    init(instanceCount: Int) {
        assert(instanceCount > 0, "The number of instances should be >0")
        self.instances = [Instance](repeating: Instance(transform: Transform(), material: Material.white), count: instanceCount)
        let device = Renderer.shared.device
        uniformBuffer = device!.makeBuffer(length: Renderer.NumSyncBuffers * MemoryLayout<Instance>.size * instanceCount, options: [])
        uniformBuffer.label = "primUniforms"
    }
    
    convenience init?(_ primitive: Primitive, without instanceIndex: Int) {
        let count = primitive.instances.count
        if instanceIndex >= count {
            return nil
        }
        self.init(instanceCount: count - 1)
        var j = 0
        for i in 0..<count {
            if i == instanceIndex {
                continue
            }
            self.instances[j] = primitive.instances[i]
            j += 1
        }
        for (uuid, i) in primitive.uuidInstanceMap {
            if i == instanceIndex {
                continue
            }
            self.uuidInstanceMap[uuid] = i
        }
        self.name = primitive.name
        self.lightingType = primitive.lightingType
        copyAlbedos(from: primitive)
    }
    
    convenience init(_ primitive: Primitive, add instance: Instance) {
        let count = primitive.instances.count
        self.init(instanceCount: count + 1)
        self.instances = primitive.instances
        self.instances.append(instance)
        self.name = primitive.name
        self.lightingType = primitive.lightingType
        copyAlbedos(from: primitive)
    }
    
    private func copyAlbedos(from primitive: Primitive) {
        for i in 0..<submeshes.count {
            submeshes[i].albedoTexture = primitive.submeshes[i].albedoTexture
            submeshes[i].sampler = primitive.submeshes[i].sampler
        }
    }
    
    func drawMesh(encoder: MTLRenderCommandEncoder, mesh: Mesh) {
        encoder.drawIndexedPrimitives(type: .triangle, indexCount: mesh.numIndices, indexType: .uint16, indexBuffer: mesh.indexBuffer, indexBufferOffset: 0, instanceCount: self.instanceCount)
    }
    
    public func queue() {
        switch lightingType {
        case .LitOpaque:
            let p: LitOpaquePlugin? = Renderer.shared.getPlugin()
            p?.queue(self)
        case .UnlitOpaque:
            let p: UnlitOpaquePlugin? = Renderer.shared.getPlugin()
            p?.queue(self)
        case .UnlitTransparent:
            let p : UnlitTransparencyPlugin? = Renderer.shared.getPlugin()
            p?.queue(self)
        }
    }
    
    public func dequeue() {
        let p1: LitOpaquePlugin? = Renderer.shared.getPlugin()
        let p2: UnlitOpaquePlugin? = Renderer.shared.getPlugin()
        let p3: UnlitTransparencyPlugin? = Renderer.shared.getPlugin()
        // just in case, dequeue from all
        p1?.dequeue(self)
        p2?.dequeue(self)
        p3?.dequeue(self)
    }
    
    // this gets called when we need to update the buffers used by the GPU
    func updateBuffers(_ syncBufferIndex: Int) {
        let uniformB = uniformBuffer.contents()
        bufferOffset = MemoryLayout<Instance>.size * instances.count * syncBufferIndex
        let uniformData = uniformB.advanced(by: bufferOffset).assumingMemoryBound(to: Float.self)
        memcpy(uniformData, &instances, MemoryLayout<Instance>.size * instances.count)
    }
    
    public func setAlbedoTexture(resource: String, bundle: Bundle, options: TextureLoadOptions?, addToCache: Bool, completion: @escaping (Error?) -> Void) {
        for i in 0..<submeshes.count {
            Renderer.shared.textureLibrary.getTextureAsync(resource: resource, bundle: bundle, options: options, addToCache: addToCache) { [weak self] (texture, error) in
                self?.submeshes[i].albedoTexture = texture
            }
        }
    }
    
    public func setAlbedoTexture(id: String, remoteUrl: URL, options: TextureLoadOptions?, addToCache: Bool, completion: @escaping (Error?) -> Void) {
        for i in 0..<submeshes.count {
            Renderer.shared.textureLibrary.getTextureAsync(id: id, remoteUrl: remoteUrl, options: options, addToCache: addToCache) { [weak self] (texture, error) in
                self?.submeshes[i].albedoTexture = texture
                completion(error)
            }
        }
    }
    
    // sets albedo to nil, basically defaulting to a white texture
    public func clearAlbedo() {
        for i in 0..<submeshes.count {
            self.submeshes[i].albedoTexture = nil
        }
    }
    
    func getTriangles() -> [Triangle] {
        return []
    }
    
    func getSurfaceIntersection(ray: Ray) -> SurfaceIntersection? {
        let triangles = getTriangles()
        var dist = Float.greatestFiniteMagnitude
        var transform = Transform()
        var point = float3(0,0,0)
        var triangle: Triangle?
        for i in instances {
            // Convert the ray to model space, less operations
            // than converting all the triangles to world space.
            // And because there may be anisotropic scaling,
            // use matrices intead of Transforms.
            let toModel = i.transform.toMatrix4().inverse
            let modelRay = toModel * ray
            for t in triangles {
                if let d = modelRay.intersects(triangle: t), d < dist {
                    dist = d
                    triangle = t
                    transform = i.transform
                    point = modelRay.travelDistance(d: d)
                }
            }
        }
        guard let t = triangle else {
            return nil
        }
        // convert triangle & point to world space
        let wt = transform * t
        point = transform * point
        // real distance will depend on scale
        dist = distance(point, ray.start)
        return SurfaceIntersection(distance: dist, point: point, normal: wt.getNormal())
    }
}
