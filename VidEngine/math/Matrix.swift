//
//  Matrix.swift
//
//  Created by David Gavilan on 2/10/15.
//  Copyright (c) 2015 David Gavilan. All rights reserved.
//

import Foundation
import Accelerate

/* 4x4 Matrix, Column-major
 * m[column, row]
 * m[column] returns a Vector4 column
 */
struct Matrix4 {
    static let identity : Matrix4 = Matrix4(
        cx: Vector4(x: 1, y: 0, z: 0, w: 0),
        cy: Vector4(x: 0, y: 1, z: 0, w: 0),
        cz: Vector4(x: 0, y: 0, z: 1, w: 0),
        cw: Vector4(x: 0, y: 0, z: 0, w: 1))
    
    var cx = Vector4()
    var cy = Vector4()
    var cz = Vector4()
    var cw = Vector4()
    
    subscript(column: Int, row: Int) -> Float {
        get {
            return self[column][row]
        }
        set {
            self[column][row] = newValue
        }
    }
    subscript(column: Int) -> Vector4 {
        get {
            return column == 0 ? cx : column == 1 ? cy : column == 2 ? cz : cw
        }
        set {
            switch(column) {
            case 0:
                cx = newValue
                break
            case 1:
                cy = newValue
                break
            case 2:
                cz = newValue
                break
            case 3:
                cw = newValue
                break
            default:
                break
            }
        }
    }
    
    static func CreateFrustum(left left: Float,right: Float,bottom: Float,top: Float,near: Float,far: Float) -> Matrix4
    {
        var m = Matrix4()
        m[0,0] = 2 * near / (right - left)
        m[1,1] = 2 * near / (top - bottom)
        m[0,2] = (right + left) / (right - left)
        m[1,2] = (top + bottom) / (top - bottom)
        m[2,2] = -(far + near) / (far - near)
        m[3,2] = -1
        m[2,3] = -2 * far * near / (far - near)
        return m
    }
    static func Perspective(fov fov: Float,near: Float, far: Float, aspectRatio: Float) -> Matrix4 {
        let size = near * tanf(0.5*DegToRad(fov))
        return Matrix4.CreateFrustum(left: -size, right: size,
                                     bottom: -size / aspectRatio, top: size / aspectRatio,
                                     near: near, far: far)
    }
    // Inverses
    static func CreateFrustumInverse(left left: Float,right: Float,bottom: Float,top: Float,near: Float,far: Float) -> Matrix4
    {
        var m = Matrix4()
        let invNear = 0.5 / near;
        let invNearFar = invNear / far
        m[0,0] = (right - left) * invNear
        m[0,3] = (right + left) * invNear
        m[1,1] = (top - bottom) * invNear
        m[1,3] = (top + bottom) * invNear
        m[2,3] = -1
        m[3,2] = (near - far) * invNearFar
        m[3,3] = (far + near) * invNearFar
        return m
    }
    static func PerspectiveInverse(fov fov: Float,near: Float, far: Float, aspectRatio: Float) -> Matrix4 {
        let size = near * tanf(0.5*DegToRad(fov))
        return Matrix4.CreateFrustumInverse(left: -size, right: size,
                                     bottom: -size / aspectRatio, top: size / aspectRatio,
                                     near: near, far: far)
    }    
}

// -----------------------------------------------------------
// operators
// -----------------------------------------------------------

func + (left: Matrix4, right: Matrix4) -> Matrix4 {
    return Matrix4(cx: left.cx + right.cx,
                   cy: left.cy + right.cy,
                   cz: left.cz + right.cz,
                   cw: left.cw + right.cw)
}

func * (m: Matrix4, v: Vector4) -> Vector4 {
    var out = Vector4()
    out.x = m[0,0]*v.x+m[1,0]*v.y+m[2,0]*v.z+m[3,0]*v.w
    out.y = m[0,1]*v.x+m[1,1]*v.y+m[2,1]*v.z+m[3,1]*v.w
    out.z = m[0,2]*v.x+m[1,2]*v.y+m[2,2]*v.z+m[3,2]*v.w
    out.w = m[0,3]*v.x+m[1,3]*v.y+m[2,3]*v.z+m[3,3]*v.w
    return out
}

func * (v: Vector4, m: Matrix4) -> Vector4 {
    var out = Vector4()
    out.x = m[0,0]*v.x+m[0,1]*v.y+m[0,2]*v.z+m[0,3]*v.w
    out.y = m[1,0]*v.x+m[1,1]*v.y+m[1,2]*v.z+m[1,3]*v.w
    out.z = m[2,0]*v.x+m[2,1]*v.y+m[2,2]*v.z+m[2,3]*v.w
    out.w = m[3,0]*v.x+m[3,1]*v.y+m[3,2]*v.z+m[3,3]*v.w
    return out
}

func * (a: Matrix4, b: Matrix4) -> Matrix4 {
    let out = Matrix4()
    // http://stackoverflow.com/a/26539600/1765629
    //vDSP_mmul(a.values, 1, b.values, 1, UnsafeMutablePointer<Float>(out.values), 1, 4, 4, 4);
    return out
}