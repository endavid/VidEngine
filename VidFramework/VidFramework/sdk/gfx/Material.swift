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
    public static let white = Material(diffuse: LinearRGBA(rgb: float3(1,1,1)))
    public var diffuse : LinearRGBA
}

/// Used to select the rendering phase.
public enum LightingType {
    case
    /// Opaque lit objects.
    LitOpaque,
    /// Unlit transparent objects.
    UnlitTransparent
}
