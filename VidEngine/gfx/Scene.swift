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
    var camera = Camera()
    var primitives : [Primitive] = []
    
    func setCamera(bounds: CGRect) {
        camera.setBounds(bounds)
    }
    
    func updateBuffers() {
        RenderManager.sharedInstance.data.projectionMatrix = camera.projectionMatrix
        RenderManager.sharedInstance.data.viewMatrix = camera.viewTransformMatrix
    }
    
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
    
    func update(currentTime: CFTimeInterval) {
    }
}