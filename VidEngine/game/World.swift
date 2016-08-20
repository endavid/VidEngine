//
//  World.swift
//  VidEngine
//
//  Created by David Gavilan on 8/20/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Foundation

class World {
    private var cubes : [CubePrimitive] = []
    
    // should be initialized after all the graphics are initialized
    init(numCubes: Int) {
        for i in 0..<numCubes {
            let cube = CubePrimitive(priority: i)
            cube.queue()
            cubes.append(cube)
        }
    }
    
}