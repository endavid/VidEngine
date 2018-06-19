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
    // To implement instanced rendering: http://metalbyexample.com/instanced-rendering/
    internal var vertexBuffer : MTLBuffer!
    public var name: String = ""
    public var perInstanceUniforms : [PerInstanceUniforms]
    let uniformBuffer : MTLBuffer!
    public var lightingType: LightingType = .LitOpaque
    var submeshes: [Mesh] = []

    public var numInstances: Int {
        get {
            return perInstanceUniforms.count
        }
    }
    // convenience getter & setter for the case we have only 1 instance
    public var transform: Transform {
        get {
            return perInstanceUniforms[0].transform
        }
        set {
            for i in 0..<numInstances {
                perInstanceUniforms[i].transform = newValue
            }
        }
    }
    // convenience getter & setter for the case we have only 1 instance
    public var material: Material {
        get {
            return perInstanceUniforms[0].material
        }
        set {
            for i in 0..<numInstances {
                perInstanceUniforms[i].material = newValue
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


    init(numInstances: Int) {
        assert(numInstances > 0, "The number of instances should be >0")
        self.perInstanceUniforms = [PerInstanceUniforms](repeating: PerInstanceUniforms(transform: Transform(), material: Material.white), count: numInstances)
        self.uniformBuffer = Renderer.shared.createPerInstanceUniformsBuffer("primUniforms", numElements: Renderer.NumSyncBuffers * numInstances)
    }

    func drawMesh(encoder: MTLRenderCommandEncoder, mesh: Mesh) {
        encoder.drawIndexedPrimitives(type: .triangle, indexCount: mesh.numIndices, indexType: .uint16, indexBuffer: mesh.indexBuffer, indexBufferOffset: 0, instanceCount: self.numInstances)
    }

    public func queue() {
        if lightingType == .LitOpaque {
            let plugin : PrimitivePlugin? = Renderer.shared.getPlugin()
            plugin?.queue(self)
        }
        else if lightingType == .UnlitTransparent {
            let plugin : UnlitTransparencyPlugin? = Renderer.shared.getPlugin()
            plugin?.queue(self)
        }
    }

    public func dequeue() {
        let p1 : PrimitivePlugin? = Renderer.shared.getPlugin()
        let p2 : UnlitTransparencyPlugin? = Renderer.shared.getPlugin()
        // just in case, dequeue from all
        p1?.dequeue(self)
        p2?.dequeue(self)
    }

    // this gets called when we need to update the buffers used by the GPU
    func updateBuffers(_ syncBufferIndex: Int) {
        let uniformB = uniformBuffer.contents()
        let uniformData = uniformB.advanced(by: MemoryLayout<PerInstanceUniforms>.size * perInstanceUniforms.count * syncBufferIndex).assumingMemoryBound(to: Float.self)
        memcpy(uniformData, &perInstanceUniforms, MemoryLayout<PerInstanceUniforms>.size * perInstanceUniforms.count)
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

    struct Mesh {
        let numIndices: Int
        let indexBuffer: MTLBuffer
        // this is not in the Material because it can only be set for ALL instances
        var albedoTexture: MTLTexture?
    }
}
