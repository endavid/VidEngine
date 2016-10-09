//
//  Scene.swift
//  VidEngine
//
//  Created by David Gavilan on 9/1/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Foundation
import UIKit
import simd

class Scene {
    var primitives : [Primitive] = []
    var camera : Camera? = nil
    
    func queueAll() {
        for p in primitives {
            p.queue()
        }
    }
    
    func dequeueAll() {
        for p in primitives {
            p.dequeue()
        }
    }
    
    func update(_ currentTime: CFTimeInterval) {
    }
}
