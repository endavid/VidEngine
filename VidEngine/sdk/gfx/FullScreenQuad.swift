//
//  FullScreenQuad.swift
//  VidEngine
//
//  Created by David Gavilan on 2017/05/29.
//  Copyright © 2017 David Gavilan. All rights reserved.
//

import MetalKit

class FullScreenQuad {
    fileprivate let indexBuffer : MTLBuffer!
    fileprivate let vertexBuffer : MTLBuffer!

    init(device: MTLDevice) {
        indexBuffer = RenderManager.sharedInstance.createIndexBuffer("fullscreen IB", elements: [0, 2, 1, 3])
        vertexBuffer = device.makeBuffer(length: 4 * MemoryLayout<float4>.size, options: [])
        vertexBuffer.label = "fullscreen VB"
        let vb = vertexBuffer.contents().assumingMemoryBound(to: float4.self)
        // (x, y, u, v)
        vb[0] = float4(-1, -1, 0, 1)
        vb[1] = float4(-1,  1, 0, 0)
        vb[2] = float4( 1, -1, 1, 1)
        vb[3] = float4( 1,  1, 1, 0)
    }

    func draw(encoder: MTLRenderCommandEncoder) {
        encoder.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
        encoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: 4, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
    }
}
