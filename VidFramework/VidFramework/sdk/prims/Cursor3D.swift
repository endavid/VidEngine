//
//  Cursor3D.swift
//  VidFramework
//
//  Created by David Gavilan on 2019/03/10.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import simd

public class Cursor3D {
    public enum TargetSurface {
        case arPlanes, all
    }
    let primitive: Primitive
    public var targetSurface = TargetSurface.arPlanes
    public var defaultDistanceFromCamera: Float = 2
    private var _show: Bool = true
    private var _intersecting: Bool = false
    
    public var intersecting: Bool {
        get {
            return _intersecting
        }
    }
    
    public var transform: Transform {
        get {
            return primitive.transform
        }
    }
    
    public var show: Bool {
        get {
            return _show
        }
        set {
            if newValue != _show {
                _show = newValue
                if newValue {
                    primitive.queue()
                } else {
                    primitive.dequeue()
                }
            }
        }
    }
    
    public init(primitive: Primitive) {
        self.primitive = primitive
        primitive.queue()
    }
    
    func set(position: simd_float3, rotation: Quaternion) {
        primitive.transform.position = position
        primitive.transform.rotation = rotation
    }
    func setIntersection(_ value: Bool) {
        _intersecting = value
    }
    
}
