//
//  MdlParser.swift
//  VidEngine
//
//  Created by David Gavilan on 9/1/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Foundation
import simd

class MdlParser {
    let path : String
    let scene : Scene
    let separators = NSCharacterSet.whitespaceCharacterSet()
    private var lines : [String] = []
    private var fnMap : [String : (String) -> ()] = [:]
    private var vertices : [TexturedVertex] = []
    private var triangles : [UInt16] = []
    
    init(path: String) {
        self.path = path
        self.scene = Scene()
        fnMap = [
            "cmplxPly": readComplexPolygon,
            "cmr": readCamera,
            "plnrMsh": readPlanarMesh,
            "plygn": readPolygon,
            "vrtxPstn": readVertexPosition
        ]
    }
    
    func parse() -> Scene {
        do {
            let text = try String(contentsOfFile: path, encoding: NSUTF8StringEncoding)
            lines = text.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
            while !lines.isEmpty {
                let line = lines.removeAtIndex(0)
                let components = getComponents(line)
                if components.count > 0 {
                    if let fn = fnMap[components[0]] {
                        fn(line)
                    }
                }
            }
        } catch _ {
            print ("ERROR: couldn't load dictionary file")
        }
        return scene
    }
    
    private func getComponents(line: String) -> [String] {
        var components = line.componentsSeparatedByCharactersInSet(separators)
        components = components.filter { $0 != "" }
        return components
    }
    
    private func advance() -> String? {
        let line = lines.removeAtIndex(0)
        let components = getComponents(line)
        if components.count > 0 {
            if let fn = fnMap[components[0]] {
                fn(line)
            } else {
                return components[0]
            }
        }
        return nil
    }
    
    private func computeNormals() {
        let numTriangles = triangles.count / 3
        for i in 0..<numTriangles {
            let i0 = Int(triangles[3 * i])
            let i1 = Int(triangles[3 * i + 1])
            let i2 = Int(triangles[3 * i + 2])
            let v0 = vertices[i0]
            let v1 = vertices[i1]
            let v2 = vertices[i2]
            let a = float3(v0.position)
            let b = float3(v1.position)
            let c = float3(v2.position)
            let bc = normalize(c - b)
            let ba = normalize(a - b)
            let normal = cross(bc, ba)
            vertices[i0] = TexturedVertex(position: v0.position, normal: Vec3(normal), uv: v0.uv)
            vertices[i1] = TexturedVertex(position: v1.position, normal: Vec3(normal), uv: v1.uv)
            vertices[i2] = TexturedVertex(position: v2.position, normal: Vec3(normal), uv: v2.uv)
        }
    }
    
    private func readPlanarMesh(header: String) {
        var head = ""
        while head != "end" {
            if let h = advance() {
                head = h
            }
        }
        computeNormals()
        let model = ModelPrimitive(vertices: vertices, triangles: triangles)
        scene.primitives.append(model)
        vertices.removeAll()
        triangles.removeAll()
    }
    
    private func readVertexPosition(header: String) {
        var head = ""
        while head != "end" {
            let line = lines.removeAtIndex(0)
            let components = getComponents(line)
            if components.count == 3 {
                let x = Float(components[0])
                let y = Float(components[1])
                let z = Float(components[2])
                let pos = Vec3(x ?? 0, y ?? 0, z ?? 0)
                let v = TexturedVertex(position: pos, normal: Vec3(0,1,0), uv: Vec2(0,0))
                vertices.append(v)
            } else if components.count > 0 {
                head = components[0]
            }
        }
    }
    
    private func readComplexPolygon(header: String) {
        var head = ""
        while head != "end" {
            if let h = advance() {
                head = h
            }
        }
    }
    
    private func readPolygon(header: String) {
        var polygon : [UInt16] = []
        var components = getComponents(header)
        var head = components.removeAtIndex(0)
        while head != "end" {
            if let i = UInt16(head) {
                polygon.append(i)
            }
            if components.isEmpty {
                let line = lines.removeAtIndex(0)
                components = getComponents(line)
            }
            head = components.removeAtIndex(0)
        }
        triangles = triangularizePolygon(polygon)
    }
    
    private func triangularizePolygon(indices: [UInt16]) -> [UInt16] {
        var tris : [UInt16] = []
        // should apply something like the ear-clipping algorithm, but for now assume we only have quads in our data
        let numTriangles = CeilDiv(indices.count, b: 3)
        for t in 0..<numTriangles {
            let i0 = (2 * t) % indices.count
            let i1 = (2 * t + 1) % indices.count
            let i2 = (2 * t + 2) % indices.count
            tris.append(UInt16(i0))
            tris.append(UInt16(i1))
            tris.append(UInt16(i2))
        }
        return tris
    }
    
    private func readCamera(header: String) {
        var c = getComponents(lines.removeAtIndex(0))
        let eyePoint = float3(Float(c[0]) ?? 0, Float(c[1]) ?? 0, Float(c[2]) ?? 0)
        //scene.camera.transform.position = eyePoint
        c = getComponents(lines.removeAtIndex(0))
        let viewDirection = float3(Float(c[0]) ?? 0, Float(c[1]) ?? 0, Float(c[2]) ?? 0)
        c = getComponents(lines.removeAtIndex(0))
        let up = float3(Float(c[0]) ?? 0, Float(c[1]) ?? 0, Float(c[2]) ?? 0)
        scene.camera.setViewDirection(viewDirection, up: up)
        scene.camera.setEyePosition(eyePoint)
        c = getComponents(lines.removeAtIndex(0))
        let focalDistance = Float(c[0]) ?? 0
        c = getComponents(lines.removeAtIndex(0))
        //let width = Float(c[0]) ?? 0
        //let height = Float(c[1]) ?? 0
        c = getComponents(lines.removeAtIndex(0))
        //let centerx = Float(c[0]) ?? 0
        //let centery = Float(c[1]) ?? 0
        c = getComponents(lines.removeAtIndex(0))
        //let time = Float(c[0]) ?? 0
        scene.camera.setPerspectiveProjection(fov: 45, near: focalDistance, far: 5000)
        var head = ""
        while head != "end" {
            if let h = advance() {
                head = h
            }
        }
    }
}