//
//  File.swift
//  
//
//  Created by David Gavilan Ruiz on 06/03/2024.
//

import Testing
import MetalKit
import simd
@testable import VidEngine


struct RendererTests {
    @Test func testMissingDevice() async throws {
        // MainActor is necessary to avoid warning:
        // _TSGetMainThread_block_invoke():Main thread potentially initialized incorrectly, cf <rdar://problem/67741850>
        let view = await MainActor.run {
            MTKView(frame: CGRect(), device: nil)
        }
        do {
            _ = try Renderer(view: view)
        } catch {
            #expect(error as? RenderError == .missingDevice)
        }
    }
    @Test func testRenderer() async throws {
        let frame = CGRect(x: 0, y: 0, width: 320, height: 240)
        let device = try #require(MTLCreateSystemDefaultDevice())
        print("ℹ Device family: \(device.family)")
        let view = await MTKView(frame: frame, device: device)
        let renderer = try Renderer(view: view)
        let cube = CubePrimitive(renderer: renderer, instanceCount: 1)
        cube.lightingType = .UnlitOpaque
        cube.transform.position = [0, 0, -5]
        cube.queue(renderer)
        let commandQueue = try #require(device.makeCommandQueue())
        let commandBuffer = try #require(commandQueue.makeCommandBuffer())
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
             commandBuffer.addCompletedHandler { _ in
                 continuation.resume()
             }
            // Schedule the draw on the MainActor, after handler is attached
            Task { @MainActor in
                renderer.draw(view, commandBuffer: commandBuffer)
            }
        }        
        let cgImage = try #require(renderer.getTextureAsImage(GBufferTexture.shaded))
        // Save as PNG
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("rendered_output.png")
        
        if #available(macOS 13.0, iOS 14.0, *) {
            CGImageWriteToFile(cgImage, filename: outputURL)
            print("✅ Saved rendered output to \(outputURL.path)")
        } else {
            // Fallback on earlier versions
        }
    }
}
