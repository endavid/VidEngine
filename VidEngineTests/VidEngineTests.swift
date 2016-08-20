//
//  VidEngineTests.swift
//
//  Created by David Gavilan on 3/31/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import XCTest
import simd
@testable import VidEngine

class VidEngineTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testVector2() {
        var v = float2(0, 3)
        XCTAssertEqual(0, v.x)
        XCTAssertEqual(3, v.y)
        XCTAssertEqual(4 * 2, sizeof(float2))
        let unsafe = UnsafeMutablePointer<Float>.alloc(2)
        memcpy(unsafe, &v, sizeof(float2))
        XCTAssertEqual(0, unsafe[0])
        XCTAssertEqual(3, unsafe[1])
        unsafe.dealloc(2)
    }
    
    func testMatrix4() {
        var m = Matrix4()
        XCTAssertEqual(0, m[3,3])
        XCTAssertEqual(4 * 4 * 4, sizeof(Matrix4))
        // [column, row], so this sets the translation
        m[3,0] = 1
        m[3,1] = 3
        m[3,2] = 9
        let unsafe = UnsafeMutablePointer<Float>.alloc(4 * 4)
        memcpy(unsafe, &m, sizeof(Matrix4))
        // check that indeed the data is stored in column-major order
        XCTAssertEqual(1, unsafe[12])
        XCTAssertEqual(3, unsafe[13])
        XCTAssertEqual(9, unsafe[14])
        unsafe.dealloc(4 * 4)
    }
    
}
