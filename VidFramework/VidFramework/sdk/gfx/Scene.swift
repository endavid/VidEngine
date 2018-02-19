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

open class Scene {
    public var primitives : [Primitive] = []
    public var camera : Camera? = nil
    
    public func queueAll() {
        for p in primitives {
            p.queue()
        }
    }
    
    public func dequeueAll() {
        for p in primitives {
            p.dequeue()
        }
    }
    
    open func update(_ currentTime: CFTimeInterval) {
    }
    
    public init() {
    }
}
