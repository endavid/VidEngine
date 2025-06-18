//
//  MemoryTests.swift
//  VidTestsTests
//
//  Created by David Gavilan on 2019/04/19.
//  Copyright © 2019 David Gavilan. All rights reserved.
//
//  Ref. https://swiftunboxed.com/internals/size-stride-alignment/

import Testing
import Foundation
import simd
@testable import VidEngine

struct MemoryTests {
    @Test func testPrimitiveInstance() {
        #expect(82 == MemoryLayout<Primitive.Instance>.size)
        #expect(96 == MemoryLayout<Primitive.Instance>.stride)
        // the alignment is 16 because we have some float4 (SIMD)
        #expect(16 == MemoryLayout<Primitive.Instance>.alignment)
    }
    
    @Test func testVector2() {
        var v = simd_float2(0, 3)
        #expect(0 == v.x)
        #expect(3 == v.y)
        #expect(4 * 2 == MemoryLayout<simd_float2>.size)
        let unsafe = UnsafeMutablePointer<Float>.allocate(capacity: 2)
        memcpy(unsafe, &v, MemoryLayout<simd_float2>.size)
        #expect(0 == unsafe[0])
        #expect(3 == unsafe[1])
        unsafe.deallocate()
    }

}

/*
class MemoryTests: XCTestCase {
    func testWorldTouch() {
        XCTAssertEqual(18, MemoryLayout<WorldTouch.Point>.size)
        XCTAssertEqual(20, MemoryLayout<WorldTouch.Point>.stride)
        XCTAssertEqual(4, MemoryLayout<WorldTouch.Point>.alignment)
    }
}
*/
