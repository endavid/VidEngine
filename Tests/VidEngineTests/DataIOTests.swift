//
//  File.swift
//  
//
//  Created by David Gavilan Ruiz on 29/02/2024.
//

import XCTest
@testable import VidEngine

class DataIOTests: XCTestCase {
    // async tests: https://developer.apple.com/documentation/xctest/asynchronous_tests_and_expectations
    func testLoadJson() async throws {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "dummy", withExtension: "json"),
            "Expected file url")
        let json = try await DataIO.loadJson(url: url)
        let obj = try XCTUnwrap(json, "Expected non-nil object")
        let hello = try XCTUnwrap(obj["Hello"], "Expected `Hello` key") as? String
        let array = try XCTUnwrap(obj["Array"], "Expected `Array` key") as? [NSNumber]
        XCTAssertEqual("Hi World", hello)
        XCTAssertEqual([1, 2, 3], array)
    }
}
