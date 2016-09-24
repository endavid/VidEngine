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
    var projectionMatrix = Matrix4()
    var inverseProjectionMatrix = Matrix4()
    var bounds = CGRect(x: 0, y: 0, width: 1, height: 1)
    var fov : Float = 45
    var near : Float = 0.1
    var far : Float = 100
    
    var viewTransform : Transform {
        get {
            return transform.inverse()
        }
    }
    var viewTransformMatrix : Matrix4 {
        get {
            return self.viewTransform.toMatrix4()
        }
    }

    func setBounds(_ bounds: CGRect) {
        self.bounds = bounds
        setPerspectiveProjection(fov: fov, near: near, far: far)
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
        projectionMatrix = Matrix4.Perspective(fov: fov, near: near, far: far, aspectRatio: aspectRatio)
        // remember inverse projection as well. Handy for casting rays
        inverseProjectionMatrix = Matrix4.PerspectiveInverse(fov: fov, near: near, far: far, aspectRatio: aspectRatio);
    }

}
