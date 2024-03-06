//
//  File.swift
//  
//
//  Created by David Gavilan Ruiz on 06/03/2024.
//

import Foundation

import XCTest
import simd
@testable import VidEngine

class GeometryTests: XCTestCase {
    func testSubdivisionSphere() {
        let sphere = SubdivisionSphere(widthSegments: 4, heightSegments: 4)
        XCTAssertEqual(24, sphere.faces.count)
        XCTAssertEqual(25, sphere.uvs.count)
        XCTAssertEqual(25, sphere.vertices.count)
        let expectedRadius: Float = 0.5
        for v in sphere.vertices {
            assertAlmostEqual(expectedRadius, length(v))
        }
    }
    func testTetrahedron() {
        let solid = PlatonicSolid.createTetrahedron()
        XCTAssertEqual(4, solid.faces.count)
        XCTAssertEqual(4, solid.vertices.count)
        XCTAssertEqual(6, solid.numEdges)
        let expectedRadius: Float = 1.0
        for v in solid.vertices {
            assertAlmostEqual(expectedRadius, length(v))
        }
    }
    func testOctahedron() {
        let solid = PlatonicSolid.createOctahedron()
        XCTAssertEqual(8, solid.faces.count)
        XCTAssertEqual(6, solid.vertices.count)
        XCTAssertEqual(12, solid.numEdges)
        let expectedRadius: Float = 1.0
        for v in solid.vertices {
            assertAlmostEqual(expectedRadius, length(v))
        }
    }
    func testIcosahedron() {
        let solid = PlatonicSolid.createIcosahedron()
        XCTAssertEqual(20, solid.faces.count)
        XCTAssertEqual(12, solid.vertices.count)
        XCTAssertEqual(30, solid.numEdges)
        let expectedRadius: Float = 1.0
        for v in solid.vertices {
            assertAlmostEqual(expectedRadius, length(v))
        }
    }
    func testSubdivision() {
        let solid = PlatonicSolid.createTetrahedron()
        solid.subdivide()
        XCTAssertEqual(20, solid.faces.count)
        XCTAssertEqual(10, solid.vertices.count)
        XCTAssertEqual(20, solid.numEdges)
        let expectedRadius: Float = 1.0
        for v in solid.vertices {
            assertAlmostEqual(expectedRadius, length(v))
        }
    }
}
