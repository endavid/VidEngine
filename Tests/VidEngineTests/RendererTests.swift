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
        cube.lightingType = .unlitOpaque
        cube.transform.position = [0, 0, -5]
        cube.transform.rotation = Quaternion(AngleAxis(angle: 0.5, axis: normalize([1, 1, 0])))
        cube.queue(renderer)
        let plane = PlanePrimitive(instanceCount: 1)
        plane.lightingType = .unlitOpaque
        plane.transform.scale = [2, 1, 1]
        plane.transform.position = [0, 0, -5.5]
        plane.transform.rotation = Quaternion(AngleAxis(angle: 1.57, axis: normalize([1, 0, 0])))
        plane.queue(renderer)
        await renderer.camera.setBounds(view.bounds)
        renderer.camera.rotation = Quaternion()
        // the number of visible instances = 0 before the first update
        renderer.updateBuffers()
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
