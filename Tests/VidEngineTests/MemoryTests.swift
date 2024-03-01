//
//  MemoryTests.swift
//  VidTestsTests
//
//  Created by David Gavilan on 2019/04/19.
//  Copyright © 2019 David Gavilan. All rights reserved.
//
//  Ref. https://swiftunboxed.com/internals/size-stride-alignment/

import XCTest
import simd
@testable import VidEngine

class MemoryTests: XCTestCase {
    func testPrimitiveInstance() {
        XCTAssertEqual(82, MemoryLayout<Primitive.Instance>.size)
        XCTAssertEqual(96, MemoryLayout<Primitive.Instance>.stride)
        // the alignment is 16 because we have some float4 (SIMD)
        XCTAssertEqual(16, MemoryLayout<Primitive.Instance>.alignment)
    }
    
    /*
    func testWorldTouch() {
        XCTAssertEqual(18, MemoryLayout<WorldTouch.Point>.size)
        XCTAssertEqual(20, MemoryLayout<WorldTouch.Point>.stride)
        XCTAssertEqual(4, MemoryLayout<WorldTouch.Point>.alignment)
    }*/
    
    func testVector2() {
        var v = simd_float2(0, 3)
        XCTAssertEqual(0, v.x)
        XCTAssertEqual(3, v.y)
        XCTAssertEqual(4 * 2, MemoryLayout<simd_float2>.size)
        let unsafe = UnsafeMutablePointer<Float>.allocate(capacity: 2)
        memcpy(unsafe, &v, MemoryLayout<simd_float2>.size)
        XCTAssertEqual(0, unsafe[0])
        XCTAssertEqual(3, unsafe[1])
        unsafe.deallocate()
    }
}
