//
//  Camera.swift
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
//
import simd
import Foundation

public class Camera {
    var bounds = CGRect(x: 0, y: 0, width: 1, height: 1)
    var fov : Float = 45
    var near : Float = 0.1
    var far : Float = 100
    private var _transform = Transform()
    private var _viewMatrix = float4x4()
    private var _projection = float4x4()
    private var _projectionInverse = float4x4()
    
    /// width / height. Smaller than one for portrait orientations.
    public var aspect: CGFloat {
        get {
            return bounds.width / bounds.height
        }
    }

    /// position and direction of the camera
    public var transform: Transform {
        get {
            return _transform
        }
        set {
            _transform = newValue
            _viewMatrix = self.viewTransform.toMatrix4()
        }
    }
    /// camera rotation
    public var rotation: Quaternion {
        get {
            return transform.rotation
        }
        set {
            transform.rotation = newValue
        }
    }
    /// inverse of the transform, to convert to view space
    public var viewTransform: Transform {
        get {
            // it shouldn't throw, as there's no anisotropic scaling
            let inv = try? transform.inverse()
            return inv!
        }
    }
    public var viewMatrix: float4x4 {
        get {
            return _viewMatrix
        }
    }
    public var projection: float4x4 {
        get {
            return _projection
        }
        set {
            _projection = newValue
            _projectionInverse = newValue.inverse
        }
    }
    public var projectionInverse: float4x4 {
        get {
            return _projectionInverse
        }
    }

    public func setBounds(_ bounds: CGRect) {
        self.bounds = bounds
        setPerspectiveProjection(fov: fov, near: near, far: far)
    }
    
    public func getUpVector() -> simd_float3 {
        // up vector at start is (0,1,0)
        return transform.rotation * simd_float3(0,1,0)
    }
    
    public func getGazeRay() -> Ray {
        let viewDirection = transform.rotation * simd_float3(0,0,-1)
        let p = transform.position
        return Ray(start: p, direction: viewDirection)
    }
    
    public func setViewDirection(_ dir: simd_float3, up: simd_float3) {
        // at start, camera is looking at -Z
        transform.rotation = Quaternion.createRotation(start: simd_float3(0,0,-1), end: dir, up: up)
    }
    
    public func setViewDirection(target: simd_float3, up: simd_float3) {
        let dir = normalize(target - transform.position)
        setViewDirection(dir, up: up)
    }
    
    public func setEyePosition(_ pos: simd_float3) {
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
        _projection = float4x4.perspective(fov: fov, near: near, far: far, aspectRatio: aspectRatio)
        // remember inverse projection as well. Handy for casting rays
        _projectionInverse = float4x4.perspectiveInverse(fov: fov, near: near, far: far, aspectRatio: aspectRatio);
    }
    
    /// The screen coordinates must be normalized between -1 and 1
    public func rayFromScreenCoordinates(x: Float, y: Float) -> Ray {
        let p = transform.position
        let screenHalfway = simd_float4(x, y, 0.75, 1)
        let viewW = projectionInverse * screenHalfway
        let viewHalfWay = simd_float3(viewW.x, viewW.y, viewW.z) * (1.0 / viewW.w)
        let worldHalfWay = transform * viewHalfWay
        return Ray(start: p, direction: normalize(worldHalfWay - p))
    }
    
    public init() {
    }
}
