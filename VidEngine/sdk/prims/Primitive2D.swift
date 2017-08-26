//
//  Primitive2D.swift
//  VidEngine
//
//  Created by David Gavilan on 10/3/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import MetalKit

struct Primitive2DOptions : OptionSet {
    let rawValue: Int

    static let alignCenter  = Primitive2DOptions(rawValue: 1 << 0)
    static let alignBottom = Primitive2DOptions(rawValue: 1 << 1)
    static let allowRotation = Primitive2DOptions(rawValue: 1 << 2)
}

class Primitive2D {
    let priority : Int
    var position = Vec3(0,0,0)
    var color = UIColor.white
    var options : Primitive2DOptions = []

    func queue() {
        let plugin : Primitive2DPlugin? = RenderManager.sharedInstance.getPlugin()
        plugin?.queue(self)
    }

    func dequeue() {
        let plugin : Primitive2DPlugin? = RenderManager.sharedInstance.getPlugin()
        plugin?.dequeue(self)
    }

    init(priority: Int) {
        self.priority = priority
    }
}

class SpritePrimitive2D : Primitive2D {
    var width : Float = 1
    var height : Float = 1
    private var _angle : Float = 0
    private var _cosa : Float = 1
    private var _sina : Float = 0

    var angle : Float {
        get {
            return _angle
        }
        set {
            _angle = newValue
            _cosa = cosf(_angle)
            _sina = sinf(_angle)
        }
    }
    var cosa : Float {
        get {
            return _cosa
        }
    }
    var sina : Float {
        get {
            return _sina
        }
    }
}
