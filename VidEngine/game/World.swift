//
//  World.swift
//  VidEngine
//
//  Created by David Gavilan on 8/20/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Foundation
import simd

class World {
    private var cubes : [CubePrimitive] = []
    
    // should be initialized after all the graphics are initialized
    init(numCubes: Int) {
        let size = getRowsPerColumns(numCubes)
        let numColumns = size.1
        let numRows = size.0
        let cubeSize = float2(1, 1)
        let marginSize = float2(0.2, 0.2)
        let totalWidth = Float(numColumns) * cubeSize.x + Float(numColumns-1) * marginSize.x
        let totalHeight = Float(numRows) * cubeSize.y + Float(numRows-1) * marginSize.y
        let startPoint = float2(-0.5*totalWidth, -0.5*totalHeight)
        for i in 0..<numRows {
            for j in 0..<numColumns {
                let x = startPoint.x + Float(j) * (cubeSize.x + marginSize.x)
                let y = startPoint.y + Float(i) * (cubeSize.y + marginSize.y)
                let cube = CubePrimitive(priority: i)
                cube.transform.position = float3(x, y, 0)
                cube.queue()
                cubes.append(cube)
            }
        }
    }
    
    private func getRowsPerColumns(objectCount: Int) -> (Int, Int) {
        let rows = 4
        let columns = Int(ceil( Double(objectCount) / Double(rows)))
        return (rows, columns)
    }
}