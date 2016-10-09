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
        initSprites()
    }
    
    private func initSprites() {
        let sprite = SpritePrimitive2D(priority: 0)
        sprite.options = [.alignCenter]
        sprite.position = Vec3(0, -0.75, 0)
        sprite.width = 40
        sprite.height = 20
        sprite.queue()
    }
    
    func update(_ currentTime: CFTimeInterval) {
        scene.update(currentTime)
    }
}
