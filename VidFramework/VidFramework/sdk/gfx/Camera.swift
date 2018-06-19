//
//  Camera.swift
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//
import simd
import UIKit

public class Camera {
    public var transform = Transform()         ///< position of the camera
    public var projectionMatrix = float4x4()
    public var inverseProjectionMatrix = float4x4()
    var bounds = CGRect(x: 0, y: 0, width: 1, height: 1)
    var fov : Float = 45
    var near : Float = 0.1
    var far : Float = 100

    public var rotation : Quaternion {
        get {
            return transform.rotation
        }
        set {
            transform.rotation = newValue
        }
    }

    public var viewTransform : Transform {
        get {
            return transform.inverse()
        }
    }
    public var viewTransformMatrix : float4x4 {
        get {
            return self.viewTransform.toMatrix4()
        }
    }

    public func setBounds(_ bounds: CGRect) {
        self.bounds = bounds
        setPerspectiveProjection(fov: fov, near: near, far: far)
    }

    public func getUpVector() -> float3 {
        // up vector at start is (0,1,0)
        return transform.rotation * float3(0,1,0)
    }

    public func setViewDirection(_ dir: float3, up: float3) {
        // at start, camera is looking at -Z
        transform.rotation = Quaternion.createRotation(start: float3(0,0,-1), end: dir, up: up)
    }

    public func setViewDirection(target: float3, up: float3) {
        let dir = normalize(target - transform.position)
        setViewDirection(dir, up: up)
    }

    public func setEyePosition(_ pos: float3) {
        transform.position = transform.rotation * pos
    }

    public func setPerspectiveProjection(fov: Float, near: Float, far: Float) {
        let aspect = Float(bounds.width / bounds.height)
        setPerspectiveProjection(fov: fov, near: near, far: far, aspectRatio: aspect)
    }

    public func setPerspectiveProjection(fov: Float, near: Float, far: Float, aspectRatio: Float)
    {
        self.fov = fov
        self.near = near
        self.far = far
        projectionMatrix = float4x4.perspective(fov: fov, near: near, far: far, aspectRatio: aspectRatio)
        // remember inverse projection as well. Handy for casting rays
        inverseProjectionMatrix = float4x4.perspectiveInverse(fov: fov, near: near, far: far, aspectRatio: aspectRatio);
    }

    public func worldFromScreenCoordinates(x: Float, y: Float) -> float3 {
        let screenHalfway = float4(x, y, 0.75, 1)
        let viewW = inverseProjectionMatrix * screenHalfway
        //let mierda = transform.toMatrix4() * inverseProjectionMatrix * screenHalfway
        //let worldHalfWay = float3(mierda.x, mierda.y, mierda.z) * (1.0 / mierda.w)
        let viewHalfWay = float3(viewW.x, viewW.y, viewW.z) * (1.0 / viewW.w)
        let worldHalfWay = transform * viewHalfWay
        print("\(transform.position) \(viewW)")
        return worldHalfWay
    }
    public init() {
    }
}
