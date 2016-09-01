//
//  World.swift
//  VidEngine
//
//  Created by David Gavilan on 8/20/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Foundation
import simd


class World {
    var scene : Scene!
    
    // should be initialized after all the graphics are initialized
    init() {
        scene = GridScene(numRows: 12, numColumns: 20)
    }
    
    func updateBuffers() {
        scene.updateBuffers()
    }
    
    func update(currentTime: CFTimeInterval) {
        scene.update(currentTime)
    }
}