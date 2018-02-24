//
//  MdlParser.swift
//  VidEngine
//
//  Created by David Gavilan on 9/1/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Foundation
import simd

public class MdlParser {
    let path : String
    let scene : Scene
    let separators = CharacterSet.whitespaces
    fileprivate var lines : [String] = []
    fileprivate var fnMap : [String : (String) -> ()] = [:]
    fileprivate var vertices : [TexturedVertex] = []
    fileprivate var triangles : [UInt16] = []
    fileprivate var spectral : [Int : Float] = [:]
    fileprivate var materials : [String : Material] = [:]
    fileprivate var materialName : String = ""
    
    public init(path: String) {
        self.path = path
        self.scene = Scene()
        fnMap = [
            "cmplxPly": readComplexPolygon,
            "cmr": readCamera,
            "lmbrtn": readLambertian,
            "mtrlNm": readMaterialName,
            "nmdMtrl": readMaterial,
            "plnrMsh": readPlanarMesh,
            "plygn": readPolygon,
            "pLmnr": readPhongLuminaire,
            "spctrl": readSpectral,
            "vrtxPstn": readVertexPosition
        ]
    }
    
    public func parse() -> Scene {
        do {
            let text = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
            lines = text.components(separatedBy: CharacterSet.newlines)
            while !lines.isEmpty {
                let line = lines.remove(at: 0)
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
    
    fileprivate func getComponents(_ line: String) -> [String] {
        var components = line.components(separatedBy: separators)
        components = components.filter { $0 != "" }
        return components
    }
    
    fileprivate func advance() -> String? {
        let line = lines.remove(at: 0)
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
    
    fileprivate func computeNormals() {
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
    
    fileprivate func readPlanarMesh(_ header: String) {
        var head = ""
        while head != "end" {
            if let h = advance() {
                head = h
            }
        }
        computeNormals()
        let model = ModelPrimitive(vertices: vertices, triangles: triangles)
        if let mat = materials[materialName] {
            model.perInstanceUniforms[0].material = mat
        }
        scene.primitives.append(model)
        vertices.removeAll()
        triangles.removeAll()
    }
    
    fileprivate func readVertexPosition(_ header: String) {
        var head = ""
        while head != "end" {
            let line = lines.remove(at: 0)
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
    
    fileprivate func readComplexPolygon(_ header: String) {
        var head = ""
        while head != "end" {
            if let h = advance() {
                head = h
            }
        }
    }
    
    fileprivate func readPolygon(_ header: String) {
        var polygon : [UInt16] = []
        var components = getComponents(header)
        var head = components.remove(at: 0)
        while head != "end" {
            if let i = UInt16(head) {
                polygon.append(i)
            }
            if components.isEmpty {
                let line = lines.remove(at: 0)
                components = getComponents(line)
            }
            head = components.remove(at: 0)
        }
        triangles = triangularizePolygon(polygon)
    }
    
    fileprivate func triangularizePolygon(_ indices: [UInt16]) -> [UInt16] {
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
    
    fileprivate func readCamera(_ header: String) {
        var c = getComponents(lines.remove(at: 0))
        let eyePoint = float3(Float(c[0]) ?? 0, Float(c[1]) ?? 0, Float(c[2]) ?? 0)
        //scene.camera.transform.position = eyePoint
        c = getComponents(lines.remove(at: 0))
        let viewDirection = float3(Float(c[0]) ?? 0, Float(c[1]) ?? 0, Float(c[2]) ?? 0)
        c = getComponents(lines.remove(at: 0))
        let up = float3(Float(c[0]) ?? 0, Float(c[1]) ?? 0, Float(c[2]) ?? 0)
        let camera = Camera()
        camera.setViewDirection(viewDirection, up: up)
        camera.setEyePosition(eyePoint)
        c = getComponents(lines.remove(at: 0))
        let focalDistance = Float(c[0]) ?? 0
        c = getComponents(lines.remove(at: 0))
        //let width = Float(c[0]) ?? 0
        //let height = Float(c[1]) ?? 0
        c = getComponents(lines.remove(at: 0))
        //let centerx = Float(c[0]) ?? 0
        //let centery = Float(c[1]) ?? 0
        c = getComponents(lines.remove(at: 0))
        //let time = Float(c[0]) ?? 0
        camera.setPerspectiveProjection(fov: 45, near: focalDistance, far: 5000)
        scene.camera = camera
        var head = ""
        while head != "end" {
            if let h = advance() {
                head = h
            }
        }
    }
    
    fileprivate func readMaterial(_ header: String) {
        let split = header.split(separator: "\"")
        let name = String(split[1])
        let c = getComponents(header)
        var head = c.last ?? ""
        var line = head
        while head != "end" {
            if let fn = fnMap[head] {
                fn(line)
            }
            line = lines.remove(at: 0)
            head = getComponents(line)[0]
        }
        let spectrum = Spectrum(data: self.spectral)
        let xyz = spectrum.toXYZ()
        let rgba = xyz.toRGBA(colorSpace: .sRGB)
        let material = Material(diffuse: rgba)
        self.materials[name] = material
    }
    
    fileprivate func readLambertian(_ header: String) {
        var head = ""
        while head != "end" {
            if let h = advance() {
                head = h
            }
        }
    }
    
    fileprivate func readPhongLuminaire(_ header: String) {
        var head = ""
        while head != "end" {
            if let h = advance() {
                head = h
            }
        }        
    }
    
    fileprivate func readSpectral(_ header: String) {
        var head = ""
        while head != "end" {
            let c = getComponents(lines.remove(at: 0))
            if c.count == 2 {
                let wavelength = Int(Float(c[0]) ?? 0)
                let intensity = Float(c[1]) ?? 0
                self.spectral[wavelength] = intensity
            }
            head = c[0]
        }
    }
    
    fileprivate func readMaterialName(_ header: String) {
        let split = header.split(separator: "\"")
        self.materialName = String(split[1])
        let c = getComponents(header)
        var head = c.last ?? ""
        while head != "end" {
            let c = getComponents(lines.remove(at: 0))
            head = c[0]
        }
    }
}
