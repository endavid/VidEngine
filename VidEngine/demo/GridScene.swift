//
//  GridScene.swift
//  VidEngine
//
//  Created by David Gavilan on 9/1/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Foundation
import UIKit
import simd

class RotationAnim {
    var startRotation = Quaternion()
    var targetRotation = Quaternion()
    var alpha : Float = 0
    var speed : Float = 1.1
    fileprivate func setRandomRotationTarget() {
        let up = float3(0, 1, 0)
        let targetDirection = Spherical.randomSample().toCartesian()
        startRotation = targetRotation
        targetRotation = Quaternion.createRotation(start: up, end: targetDirection)
        let startDirection = startRotation * up
        let cosa = dot(startDirection, targetDirection)
        let a = acos(cosa)
        speed = 2 - a / PI
    }
    func update(_ currentTime: CFTimeInterval) -> Quaternion {
        alpha = alpha + speed * Float(currentTime)
        if alpha > 1 {
            setRandomRotationTarget()
            alpha = 0
            return startRotation
        } else {
            return Slerp(startRotation, end: targetRotation, t: alpha)
        }
    }
}

class GridScene : Scene {
    fileprivate var rotationAnims : [RotationAnim] = []

    init(numRows: Int, numColumns: Int) {
        //let prim = SpherePrimitive(priority: 0, numInstances: numRows * numColumns, tessellationLevel: 2)
        let prim = CubePrimitive(numInstances: numRows * numColumns)
        let cubeSize = float2(1, 1)
        let marginSize = float2(0.2, 0.2)
        let totalWidth = Float(numColumns) * cubeSize.x + Float(numColumns-1) * marginSize.x
        let totalHeight = Float(numRows) * cubeSize.y + Float(numRows-1) * marginSize.y
        let startPoint = float2(-0.5*totalWidth+0.5*cubeSize.x, -0.5*totalHeight+0.5*cubeSize.y)
        for i in 0..<numRows {
            for j in 0..<numColumns {
                let x = startPoint.x + Float(j) * (cubeSize.x + marginSize.x)
                let y = startPoint.y + Float(i) * (cubeSize.y + marginSize.y)
                let index = i * numColumns + j
                prim.perInstanceUniforms[index].transform.position = float3(x, y, 0)
                rotationAnims.append(RotationAnim())
            }
        }
        prim.queue()
        super.init()
        primitives.append(prim)
        camera = Camera()
        camera?.setViewDirection(float3(0,0,-1), up: float3(0,1,0))
        camera?.setEyePosition(float3(0,2,20))
        camera?.setPerspectiveProjection(fov: 40, near: 0.1, far: 100)
    }
    
    override func update(_ currentTime: CFTimeInterval) {
        for i in 0..<primitives[0].numInstances {
            primitives[0].perInstanceUniforms[i].transform.rotation = rotationAnims[i].update(currentTime)
        }
    }
}
