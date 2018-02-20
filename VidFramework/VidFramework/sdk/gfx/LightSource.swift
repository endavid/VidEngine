//
//  LightSource.swift
//  VidEngine
//
//  Created by David Gavilan on 9/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Foundation

class LightSource {
    var diffuseColor : Vec3
    init(color: Vec3) {
        self.diffuseColor = color
    }
}

class DirectionalLight : LightSource {
    // the direction TO the light
    var direction : Vec3
    init(color: Vec3, direction: Vec3) {
        self.direction = direction
        super.init(color: color)
    }
}
