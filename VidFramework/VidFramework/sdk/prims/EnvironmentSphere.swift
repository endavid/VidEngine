//
//  EnvironmentSphere.swift
//  VidFramework
//
//  Created by David Gavilan on 2019/02/25.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import MetalKit

/// A 3D sphere that expects a cubemap as its albedo map
/// to sample it using the sphere normal.
/// If isInterior is true, then the front-facing triangles
/// are the ones inside the sphere.
public class EnvironmentSphere: SpherePrimitive {
    public init(isInterior: Bool, widthSegments: Int, heightSegments: Int) {
        let desc = SphereDescriptor(isInterior: isInterior, widthSegments: widthSegments, heightSegments: heightSegments)
        super.init(instanceCount: 1, descriptor: desc)
        lightingType = .UnlitOpaque
        if isInterior {
            // this is to invert normals in the shader,
            // used for sampling the cubemap correctly
            material.uvScale = Vec2(-1, -1)
        }
    }
    public func setCubemapTexture(resource: String, bundle: Bundle, addToCache: Bool, completion: @escaping (Error?) -> Void) {
        let options = TextureLoadOptions(options: nil, type: .cubemap)
        setAlbedoTexture(resource: resource, bundle: bundle, options: options, addToCache: addToCache, completion: completion)
    }
}
