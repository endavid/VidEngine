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
        if let path = Bundle.main.path(forResource: "CornellBox", ofType: "mdla") {
            print(path)
            let parser = MdlParser(path: path)
            scene = parser.parse()
            scene.queueAll()
        } else {
            scene = GridScene(numRows: 12, numColumns: 20)
        }
    }
    
    func updateBuffers() {
        scene.updateBuffers()
    }
    
    func update(_ currentTime: CFTimeInterval) {
        scene.update(currentTime)
    }
}
