//
//  File.swift
//  
//
//  Created by David Gavilan Ruiz on 29/02/2024.
//

import Testing
import Foundation
@testable import VidEngine

struct DataIOTests {
    @Test func testLoadJson() async throws {
        let url = try #require(Bundle.module.url(forResource: "dummy", withExtension: "json"))
        if #available(macOS 13.0, iOS 15.0, *) {
            let json = try await DataIO.loadJson(url: url)
            let obj = try #require(json)
            let hello = try #require(obj["Hello"] as? String)
            let array = try #require(obj["Array"] as? [NSNumber])
            #expect("Hi World" == hello)
            #expect([1, 2, 3] == array)
        } else {
            // Fallback on earlier versions
        }
    }
}

