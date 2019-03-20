//
//  Material.swift
//  VidEngine
//
//  Created by David Gavilan on 9/4/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Foundation
import simd

public struct Material {
    public static let white = Material(
        diffuse: LinearRGBA(rgb: float3(1,1,1))
    )
    /// Diffuse color, in linear RGB color space.
    public var diffuse : LinearRGBA
    /// UV scale used on textured objects.
    public var uvScale : Vec2
    /// UV offset used on textured objects.
    public var uvOffset : Vec2
    
    public init(diffuse: LinearRGBA) {
        self.diffuse = diffuse
        self.uvScale = Vec2(1,1)
        self.uvOffset = Vec2(0,0)
    }
}

/// Used to select the rendering phase.
public enum LightingType {
    case
    /// Opaque lit objects.
    LitOpaque,
    /// Opaque unlit objects.
    UnlitOpaque,
    /// Unlit transparent objects.
    UnlitTransparent
}
