//
//  MemoryTests.swift
//  VidTestsTests
//
//  Created by David Gavilan on 2019/04/19.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import XCTest
import simd
import VidFramework
@testable import VidTests

class MemoryTests: XCTestCase {
    func testPrimitiveInstance() {
        XCTAssertEqual(80, MemoryLayout<Primitive.Instance>.size)
        XCTAssertEqual(80, MemoryLayout<Primitive.Instance>.stride)
        XCTAssertEqual(16, MemoryLayout<Primitive.Instance>.alignment)
    }
}
