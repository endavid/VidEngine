//
//  Material.swift
//  VidEngine
//
//  Created by David Gavilan on 9/4/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Foundation
import simd

struct Material {
    static let white = Material(diffuse: LinearRGBA(rgb: float3(1,1,1)))
    var diffuse : LinearRGBA
}