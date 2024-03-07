//
//  File.swift
//  
//
//  Created by David Gavilan Ruiz on 06/03/2024.
//

import XCTest
import MetalKit
import simd
@testable import VidEngine


class RendererTests: XCTestCase {
    func testMissingDevice() {
        let view = MTKView(frame: CGRect(), device: nil)
        XCTAssertThrowsError(try Renderer(view: view))
    }
    func testRenderer() throws {
        let frame = CGRect(x: 0, y: 0, width: 320, height: 240)
        let device = try XCTUnwrap( MTLCreateSystemDefaultDevice(), "Expected not nil device")
        let view = MTKView(frame: frame, device: device)
        let renderer = try Renderer(view: view)
    }
}
