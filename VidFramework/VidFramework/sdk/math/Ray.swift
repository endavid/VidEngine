//
//  Ray.swift
//  VidFramework
//
//  Created by David Gavilan on 2019/03/09.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import simd

public struct Ray {
    let start: float3
    let direction: float3
    
    // https://en.wikipedia.org/wiki/Möller–Trumbore_intersection_algorithm
    func intersects(triangle: Triangle) -> Float? {
        let e1 = triangle.b - triangle.a
        let e2 = triangle.c - triangle.a
        // plane normal
        let n = cross(direction, e2)
        //if determinant is near zero, ray lies in plane of triangle or ray is parallel to plane of triangle
        let det = dot(e1, n)
        if IsClose(det, 0) {
            return nil
        }
        let invDet = 1.0 / det
        //calculate distance from point A to ray origin
        let da = start - triangle.a
        //Calculate u parameter and test bound
        let u = dot(da, n) * invDet
        //The intersection lies outside of the triangle
        if u < 0 || u > 1 {
            return nil
        }
        //Prepare to test v parameter
        let q = cross(da, e1)
        //Calculate V parameter and test bound
        let v = dot(direction, q) * invDet
        //The intersection lies outside of the triangle
        if v < 0 || (u + v) > 1 {
            return nil
        }
        // t is the distance from the ray's origin to the intersection
        let t = dot(e2, q) * invDet
        if t > GENEROUS_EPSILON {
            return t
        }
        return nil
    }
    
    func travelDistance(d: Float) -> float3 {
        return start + d * direction
    }
}

public struct SurfaceIntersection {
    let distance: Float
    let point: float3
    let normal: float3
}

public func * (t: Transform, ray: Ray) -> Ray {
    let start = t * ray.start
    let direction = t * ray.direction
    return Ray(start: start, direction: direction)
}
