//
//  VidEngineTests.swift
//
//  Created by David Gavilan on 3/31/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import XCTest
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
        var v = Vector2(x: 0, y: 3)
        XCTAssertEqual(0, v.x)
        XCTAssertEqual(3, v.y)
        XCTAssertEqual(4 * 2, sizeof(Vector2))
        let unsafe = UnsafeMutablePointer<Float>.alloc(2)
        memcpy(unsafe, &v, sizeof(Vector2))
        XCTAssertEqual(0, unsafe[0])
        XCTAssertEqual(3, unsafe[1])
        unsafe.dealloc(2)
    }
    
    func testMatrix4() {
        var m = Matrix4()
        XCTAssertEqual(0, m[3,3])
        m[0,3] = 1
        m[1,3] = 3
        m[2,3] = 9
        XCTAssertEqual(4 * 4 * 4, sizeof(Matrix4))
    }
    
}
