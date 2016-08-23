//
//  World.swift
//  VidEngine
//
//  Created by David Gavilan on 8/20/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Foundation
import simd

class RotationAnim {
    var startRotation = Quaternion()
    var targetRotation = Quaternion()
    var alpha : Float = 0
    var speed : Float = 1.1
    private func setRandomRotationTarget() {
        let up = float3(0, 1, 0)
        let targetDirection = Spherical.randomSample().toCartesian()
        startRotation = targetRotation
        targetRotation = Quaternion.createRotation(start: up, end: targetDirection)
        let startDirection = startRotation * up
        let cosa = dot(startDirection, targetDirection)
        let a = acos(cosa)
        speed = 2 - a / PI
    }
    func update(currentTime: CFTimeInterval) -> Quaternion {
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

class World {
    private var cubes : [CubePrimitive] = []
    private var rotationAnims : [RotationAnim] = []
    
    // should be initialized after all the graphics are initialized
    init(numRows: Int, numColumns: Int) {
        let cubeSize = float2(1, 1)
        let marginSize = float2(0.2, 0.2)
        let totalWidth = Float(numColumns) * cubeSize.x + Float(numColumns-1) * marginSize.x
        let totalHeight = Float(numRows) * cubeSize.y + Float(numRows-1) * marginSize.y
        let startPoint = float2(-0.5*totalWidth+0.5*cubeSize.x, -0.5*totalHeight+0.5*cubeSize.y)
        for i in 0..<numRows {
            for j in 0..<numColumns {
                let x = startPoint.x + Float(j) * (cubeSize.x + marginSize.x)
                let y = startPoint.y + Float(i) * (cubeSize.y + marginSize.y)
                let cube = CubePrimitive(priority: i)
                cube.transform.position = float3(x, y, 0)
                cube.queue()
                cubes.append(cube)
                rotationAnims.append(RotationAnim())
            }
        }
    }
        
    func update(currentTime: CFTimeInterval) {
        for i in 0..<cubes.count {
            cubes[i].transform.rotation = rotationAnims[i].update(currentTime)
        }
    }
}