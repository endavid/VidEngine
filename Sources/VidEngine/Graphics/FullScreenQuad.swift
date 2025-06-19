//
//  FullScreenQuad.swift
//  VidEngine
//
//  Created by David Gavilan Ruiz on 19/06/2025.
//
import Metal
import MetalKit

class FullScreenQuad {
    fileprivate let indexBuffer : MTLBuffer!
    fileprivate let vertexBuffer : MTLBuffer!
    fileprivate let triangleListBuffer: MTLBuffer!
    
    init(renderer: Renderer) {
        indexBuffer = renderer.createIndexBuffer("fullscreen strip", elements: [0, 2, 1, 3])
        triangleListBuffer = renderer.createIndexBuffer("fullscreen tris", elements: [0, 2, 1, 2, 1, 3])
        vertexBuffer = renderer.device.makeBuffer(length: 4 * MemoryLayout<Vec4>.size, options: [])
        vertexBuffer.label = "fullscreen VB"
        let vb = vertexBuffer.contents().assumingMemoryBound(to: Vec4.self)
        // (x, y, u, v)
        vb[0] = Vec4(-1, -1, 0, 1)
        vb[1] = Vec4(-1,  1, 0, 0)
        vb[2] = Vec4( 1, -1, 1, 1)
        vb[3] = Vec4( 1,  1, 1, 0)
    }
    
    func draw(encoder: MTLRenderCommandEncoder, instanceCount: Int = 1) {
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: 4, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: instanceCount)
    }
    
    @available(macOS 13.0, iOS 16.0, *)
    func drawMesh(encoder: MTLRenderCommandEncoder, gridWidth: Int, gridHeight: Int, threadsPerBlock: Int) {
        encoder.setObjectBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setObjectBuffer(triangleListBuffer, offset: 0, index: 1)
        let oGroups = MTLSize(width: gridWidth, height: gridHeight, depth: 1)
        let oThreads = MTLSize(width: 1, height: 1, depth: 1)
        let mThreads = MTLSize(width: threadsPerBlock, height: 1, depth: 1)
        encoder.drawMeshThreads(oGroups, threadsPerObjectThreadgroup: oThreads, threadsPerMeshThreadgroup: mThreads)
    }
}

