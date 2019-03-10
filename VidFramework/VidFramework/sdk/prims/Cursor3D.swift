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
    private var _show: Bool = true
    
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
    
    func update(intersection: SurfaceIntersection) {
        primitive.transform.position = intersection.point
        primitive.transform.rotation = Quaternion.createRotation(start: float3(0,1,0), end: intersection.normal)
    }
    
}
