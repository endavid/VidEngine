//
//  Camera.swift
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

class Camera {
    var projectionMatrix = Matrix4()
    var inverseProjectionMatrix = Matrix4()
    
    func setPerspectiveProjection(fov fov: Float, near: Float, far: Float, aspectRatio: Float)
    {
        projectionMatrix = Matrix4.Perspective(fov: fov, near: near, far: far, aspectRatio: aspectRatio)
        // remember inverse projection as well. Handy for casting rays
        inverseProjectionMatrix = Matrix4.PerspectiveInverse(fov: fov, near: near, far: far, aspectRatio: aspectRatio);
    }

}