//
//  ModelPrimitive.swift
//  VidEngine
//
//  Created by David Gavilan on 9/1/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

/// A 3D model from a file.
public class ModelPrimitive : Primitive {
    
    /// Asynchronously load a 3D model from a Json file.
    /// - parameters:
    ///   - forResource: resource name in the given Bundle.
    ///   - withExtension: extension of the resource. Although the extension can be anything, a Json file is expected.
    ///   - bundle: bundle where to look for the resource.
    ///   - completion: callback for when the resource is ready.
    public static func loadAsync(forResource res: String, withExtension ext: String, bundle: Bundle, completion: @escaping (ModelPrimitive?, Error?) -> Void) {
        // about @escaping http://stackoverflow.com/a/38990967/1765629
        guard let url = bundle.url(forResource: res, withExtension: ext) else {
            completion(nil, FileError.missing(res))
            return
        }
        // http://stackoverflow.com/a/39423764/1765629
        URLSession.shared.dataTask(with:url) { (data, response, error) in
            var model: ModelPrimitive? = nil
            if let e = error {
                NSLog(e.localizedDescription)
            } else if let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let json = json {
                    model =  ModelPrimitive(json: json, bundle: bundle)
                }
            }
            completion(model, nil)
            }.resume()
    }
    
    /// Create multiple instances of a model with a hash map from a Json file.
    public init?(json: [String: Any], bundle: Bundle?, numInstances: Int) {
        super.init(numInstances: numInstances)
        do {
            try parseJson(json, bundle: bundle)
        } catch let error {
            print(error)
            return nil
        }
    }
    
    
    /// Create model with a hash map from a Json file.
    public convenience init?(json: [String: Any], bundle: Bundle?) {
        self.init(json: json, bundle: bundle, numInstances: 1)
    }
    
    func parseJson(_ json: [String: Any], bundle: Bundle?) throws {
        guard let vertexData = json["vertices"] as? [Float] else {
            throw SerializationError.missing("vertices")
        }
        guard let meshes = json["meshes"] as? [Any] else {
            throw SerializationError.missing("meshes")
        }
        if let name = json["name"] as? String {
            self.name = name
        }
        let materials = json["materials"] as? [String: Any]
        let numVertices = vertexData.count / 8
        vertexBuffer = Renderer.shared.createTexturedVertexBuffer(name + " VB", numElements: numVertices)
        let vb = vertexBuffer.contents().assumingMemoryBound(to: TexturedVertex.self)
        for i in 0..<numVertices {
            let x = Vec3(vertexData[8*i], vertexData[8*i+1], vertexData[8*i+2])
            let n = Vec3(vertexData[8*i+3], vertexData[8*i+1+4], vertexData[8*i+2+5])
            let uv = Vec2(vertexData[8*i+6], 1-vertexData[8*i+7])
            vb[i] = TexturedVertex(position: x, normal: n, uv: uv)
        }
        for m in meshes {
            guard let meshData = m as? [String: Any] else {
                continue
            }
            guard let indices = meshData["indices"] as? [UInt16] else {
                continue
            }
            let indexBuffer = Renderer.shared.createIndexBuffer(name + " IB", elements: indices)
            let submesh = Mesh(numIndices: indices.count, indexBuffer: indexBuffer, albedoTexture: nil)
            let submeshIndex = submeshes.count
            submeshes.append(submesh)
            if let materials = materials,
                let matName = meshData["material"] as? String,
                let mat = materials[matName] as? [String: Any],
                let albedoMap = mat["albedoMap"] as? String {
                if let b = bundle {
                    Renderer.shared.textureLibrary.getTextureAsync(resource: albedoMap, bundle: b, options: nil, addToCache: true) { [weak self] (texture, error) in
                        self?.submeshes[submeshIndex].albedoTexture = texture
                    }
                } else {
                    // @todo load remote image if bundle is not provided and we have a remote URL
                }
            }
        }
    } // parseJson
    
    init(vertices: [TexturedVertex], triangles: [UInt16]) {
        super.init(numInstances: 1)
        initBuffers(vertices, triangles: triangles)
    }
    
    fileprivate func initBuffers(_ vertices: [TexturedVertex], triangles: [UInt16]) {
        vertexBuffer = Renderer.shared.createTexturedVertexBuffer("model VB", numElements: vertices.count)
        let vb = vertexBuffer.contents().assumingMemoryBound(to: TexturedVertex.self)
        for i in 0..<vertices.count {
            vb[i] = vertices[i]
        }
        let indexBuffer = Renderer.shared.createIndexBuffer("model IB", elements: triangles)
        let submesh = Mesh(numIndices: triangles.count, indexBuffer: indexBuffer, albedoTexture: nil)
        submeshes.append(submesh)
    }

}
