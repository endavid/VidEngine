//
//  Camera.swift
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//
import simd
import UIKit

class Camera {
    var transform = Transform()         ///< position of the camera
    var projectionMatrix = float4x4()
    var inverseProjectionMatrix = float4x4()
    var bounds = CGRect(x: 0, y: 0, width: 1, height: 1) {
        didSet {
            setPerspectiveProjection(fov: fov, near: near, far: far)
        }
    }
    var fov : Float = 45
    var near : Float = 0.1
    var far : Float = 100
    
    var rotation : Quaternion {
        get {
            return transform.rotation
        }
        set {
            transform.rotation = newValue
        }
    }
    
    var viewTransform : Transform {
        get {
            return transform.inverse()
        }
    }

    var viewTransformMatrix : float4x4 {
        return viewTransform.toMatrix4()
    }
    
    func getUpVector() -> float3 {
        // up vector at start is (0,1,0)
        return transform.rotation * float3(0,1,0)
    }
    
    func setViewDirection(_ dir: float3, up: float3) {
        // at start, camera is looking at -Z
        transform.rotation = Quaternion.createRotation(start: float3(0,0,-1), end: dir, up: up)
    }
    
    func setEyePosition(_ pos: float3) {
        transform.position = transform.rotation * pos
    }
    
    func setPerspectiveProjection(fov: Float, near: Float, far: Float) {
        let aspect = Float(bounds.width / bounds.height)
        setPerspectiveProjection(fov: fov, near: near, far: far, aspectRatio: aspect)
    }
    
    func setPerspectiveProjection(fov: Float, near: Float, far: Float, aspectRatio: Float)
    {
        self.fov = fov
        self.near = near
        self.far = far
        projectionMatrix = float4x4.perspective(fov: fov, near: near, far: far, aspectRatio: aspectRatio)
        // remember inverse projection as well. Handy for casting rays
        inverseProjectionMatrix = float4x4.perspectiveInverse(fov: fov, near: near, far: far, aspectRatio: aspectRatio);
    }

    func worldFromScreenCoordinates(x: Float, y: Float) -> float3 {
        let screenHalfway = float4(x, y, 0.75, 1)
        let viewW = inverseProjectionMatrix * screenHalfway
        //let mierda = transform.toMatrix4() * inverseProjectionMatrix * screenHalfway
        //let worldHalfWay = float3(mierda.x, mierda.y, mierda.z) * (1.0 / mierda.w)
        let viewHalfWay = float3(viewW.x, viewW.y, viewW.z) * (1.0 / viewW.w)
        let worldHalfWay = transform * viewHalfWay
        print("\(transform.position) \(viewW)")
        return worldHalfWay
    }
}
