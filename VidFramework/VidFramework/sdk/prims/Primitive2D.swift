//
//  Primitive2D.swift
//  VidEngine
//
//  Created by David Gavilan on 10/3/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

public struct Primitive2DOptions : OptionSet {
    public let rawValue: Int
    
    public static let alignCenter  = Primitive2DOptions(rawValue: 1 << 0)
    public static let alignBottom = Primitive2DOptions(rawValue: 1 << 1)
    public static let allowRotation = Primitive2DOptions(rawValue: 1 << 2)
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public class Primitive2D {
    public var position = Vec3(0,0,0)
    public var color = UIColor.white
    public var options : Primitive2DOptions = []
}

public class SpritePrimitive2D : Primitive2D {
    public var width : Float = 1
    public var height : Float = 1
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
    
    override public init() {
        super.init()
    }
}
