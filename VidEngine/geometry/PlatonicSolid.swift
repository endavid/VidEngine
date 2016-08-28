//
//  PlatonicSolid.swift
//  VidEngine
//
//  Created by David Gavilan on 8/28/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import simd

// http://student.ulb.ac.be/~claugero/sphere/index.html


class PlatonicSolid {
    var vertices : [float3]
    var faces : [int3]
    var numEdges : Int
    private var edgeWalk : Int = 0
    private var start : [Int] = []
    private var end : [Int] = []
    private var midpoint : [Int] = []
    
    init(numVertices: Int, numFaces: Int, numEdges: Int) {
        vertices = [float3](count: numVertices, repeatedValue: float3(0,0,0))
        faces = [int3](count: numFaces, repeatedValue: int3(0,0,0))
        self.numEdges = numEdges
    }
    
    static func createTetrahedron() -> PlatonicSolid {
        let ps = PlatonicSolid(numVertices: 4, numFaces: 4, numEdges: 6)
        let sqrt3 = 1 / sqrtf(3.0)
        ps.vertices[0] = float3( sqrt3,  sqrt3,  sqrt3)
        ps.vertices[1] = float3(-sqrt3, -sqrt3,  sqrt3)
        ps.vertices[2] = float3(-sqrt3,  sqrt3, -sqrt3)
        ps.vertices[3] = float3( sqrt3, -sqrt3, -sqrt3)
        ps.faces[0] = int3(0, 2, 1)
        ps.faces[1] = int3(0, 1, 3)
        ps.faces[2] = int3(2, 3, 1)
        ps.faces[3] = int3(3, 2, 0)
        return ps
    }
    
    static func createOctahedron() -> PlatonicSolid {
        let ps = PlatonicSolid(numVertices: 6, numFaces: 8, numEdges: 12)
        ps.vertices[0] = float3( 0,  0, -1)
        ps.vertices[1] = float3( 1,  0,  0)
        ps.vertices[2] = float3( 0, -1,  0)
        ps.vertices[3] = float3(-1,  0,  0)
        ps.vertices[4] = float3( 0,  1,  0)
        ps.vertices[5] = float3( 0,  0,  1)
        ps.faces[0] = int3(0, 1, 2)
        ps.faces[1] = int3(0, 2, 3)
        ps.faces[2] = int3(0, 3, 4)
        ps.faces[3] = int3(0, 4, 1)
        ps.faces[4] = int3(5, 2, 1)
        ps.faces[5] = int3(5, 3, 2)
        ps.faces[6] = int3(5, 4, 3)
        ps.faces[7] = int3(5, 1, 4)
        return ps
    }
    
    static func createIcosahedron() -> PlatonicSolid {
        let ps = PlatonicSolid(numVertices: 12, numFaces: 20, numEdges: 30)
        let t = (1+sqrtf(5))/2
        let tau = t/sqrtf(1+t*t)
        let one = 1/sqrtf(1+t*t)
        ps.vertices[0]  = float3( tau,  one,    0)
        ps.vertices[1]  = float3(-tau,  one,    0)
        ps.vertices[2]  = float3(-tau, -one,    0)
        ps.vertices[3]  = float3( tau, -one,    0)
        ps.vertices[4]  = float3( one,    0,  tau)
        ps.vertices[5]  = float3( one,    0, -tau)
        ps.vertices[6]  = float3(-one,    0, -tau)
        ps.vertices[7]  = float3(-one,    0,  tau)
        ps.vertices[8]  = float3(   0,  tau,  one)
        ps.vertices[9]  = float3(   0, -tau,  one)
        ps.vertices[10] = float3(   0, -tau, -one)
        ps.vertices[11] = float3(   0,  tau, -one)
        ps.faces[0]  = int3( 4, 8, 7  )
        ps.faces[1]  = int3( 4, 7, 9  )
        ps.faces[2]  = int3( 5, 6, 11 )
        ps.faces[3]  = int3( 5, 10, 6 )
        ps.faces[4]  = int3( 0, 4, 3  )
        ps.faces[5]  = int3( 0, 3, 5  )
        ps.faces[6]  = int3( 2, 7, 1  )
        ps.faces[7]  = int3( 2, 1, 6  )
        ps.faces[8]  = int3( 8, 0, 11 )
        ps.faces[9]  = int3( 8, 11, 1 )
        ps.faces[10] = int3( 9, 10, 3 )
        ps.faces[11] = int3( 9, 2, 10 )
        ps.faces[12] = int3( 8, 4, 0  )
        ps.faces[13] = int3( 11, 0, 5 )
        ps.faces[14] = int3( 4, 9, 3  )
        ps.faces[15] = int3( 5, 3, 10 )
        ps.faces[16] = int3( 7, 8, 1  )
        ps.faces[17] = int3( 6, 1, 11 )
        ps.faces[18] = int3( 7, 2, 9  )
        ps.faces[19] = int3( 6, 10, 2 )
        return ps
    }
    
    func subdivide() {
        // numVerticesNew = vertices.count + 2 * numEdges
        // numFacesNew = 4 * faces.count
        edgeWalk = 0
        numEdges = 2 * vertices.count + 3 * faces.count
        start = [Int](count: numEdges, repeatedValue: 0)
        end = [Int](count: numEdges, repeatedValue: 0)
        midpoint = [Int](count: numEdges, repeatedValue: 0)
        let facesOld = faces // it will copy the contents
        for i in 0..<faces.count {
            let f = facesOld[i]
            let ab = Int32(searchMidpoint(Int(f.y), indexEnd: Int(f.x)))
            let bc = Int32(searchMidpoint(Int(f.z), indexEnd: Int(f.y)))
            let ca = Int32(searchMidpoint(Int(f.x), indexEnd: Int(f.z)))
            faces.append(int3(f.x, ab, ca))
            faces.append(int3(ca, ab, bc))
            faces.append(int3(ca, bc, f.z))
            faces.append(int3(ab, f.y, bc))
        }
    }
    
    private func searchMidpoint(indexStart: Int, indexEnd: Int) -> Int {
        for i in 0..<edgeWalk {
            if (start[i] == indexStart && end[i] == indexEnd)
                || (start[i] == indexEnd && end[i] == indexStart) {
                let res = midpoint[i]
                start[i] = start[edgeWalk-1]
                end[i] = end[edgeWalk-1]
                midpoint[i] = midpoint[edgeWalk-1]
                edgeWalk -= 1
                return res
            }
        }
        // vertex not in the list, so we add it
        start[edgeWalk] = indexStart
        end[edgeWalk] = indexEnd
        midpoint[edgeWalk] = vertices.count
        // create new vertex
        let vs = vertices[indexStart]
        let ve = vertices[indexEnd]
        let mid = 0.5 * (vs + ve)
        vertices.append(normalize(mid))
        edgeWalk += 1
        return midpoint[edgeWalk-1]
    }
}