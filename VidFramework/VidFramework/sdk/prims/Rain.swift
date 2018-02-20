//
//  Rain.swift
//  VidFramework
//
//  Created by David Gavilan on 2018/02/18.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

public class Rain {
    fileprivate var raindropDoubleBuffer: MTLBuffer! = nil
    fileprivate var noiseTexture: MTLTexture! = nil
    fileprivate let sizeOfLineParticle = MemoryLayout<Float>.size * 4 * 2
    fileprivate let maxNumberOfRaindrops = 2048
    fileprivate var particleCount = 0
    fileprivate var vertexCount = 0
    fileprivate var doubleBufferIndex = 0

    public func queue() {
        let plugin : RainPlugin? = RenderManager.sharedInstance.getPlugin()
        plugin?.queue(self)
    }
    public func dequeue() {
        let plugin : RainPlugin? = RenderManager.sharedInstance.getPlugin()
        plugin?.dequeue(self)
    }

    public init?(numParticles: Int) {
        guard let device = RenderManager.sharedInstance.device else {
            return nil
        }
        raindropDoubleBuffer = device.makeBuffer(length: 2 * maxNumberOfRaindrops * sizeOfLineParticle, options: [])
        raindropDoubleBuffer.label = "raindrop buffer"
        noiseTexture = createNoiseTexture(device: device, width: 128, height: 128)
        initVertexBuffer(numParticles)
    }

    fileprivate func initVertexBuffer(_ numParticles: Int) {
        // vData is pointer to the MTLBuffer's Float data contents
        let pData = raindropDoubleBuffer.contents()
        particleCount = Min(maxNumberOfRaindrops, b: numParticles)
        vertexCount = 2 * particleCount
        let vertexSize = 4
        let dropLength : Float = 0.1
        for p in 0..<particleCount {
            let x = 2 * Randf() - 1
            let y = 1 + 2.4 * Randf()
            let dropSpeed = -2 * (0.9 + 0.2 * Randf())
            for i in 0..<2 { // Double buffer
                let vDatai = pData.advanced(by: maxNumberOfRaindrops * sizeOfLineParticle * i).assumingMemoryBound(to: Float.self)
                vDatai[2*vertexSize*p] = x
                vDatai[2*vertexSize*p+1] = y
                vDatai[2*vertexSize*p+2] = 0
                vDatai[2*vertexSize*p+3] = dropSpeed
                vDatai[2*vertexSize*p+4] = x
                vDatai[2*vertexSize*p+5] = y - dropLength
                vDatai[2*vertexSize*p+6] = 0
                vDatai[2*vertexSize*p+7] = dropSpeed
            }
        }
    }
    func draw(encoder: MTLRenderCommandEncoder) {
        // setVertexBuffer offset: How far the data is from the start of the buffer, in bytes
        // Check alignment in setVertexBuffer doc
        let bufferOffset = maxNumberOfRaindrops * sizeOfLineParticle
        encoder.setVertexBuffer(raindropDoubleBuffer, offset: bufferOffset*doubleBufferIndex, index: 0)
        encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: vertexCount, instanceCount: 1)
    }

    func update(encoder: MTLRenderCommandEncoder) {
        let bufferOffset = maxNumberOfRaindrops * sizeOfLineParticle
        encoder.setVertexBuffer(raindropDoubleBuffer, offset: bufferOffset*doubleBufferIndex, index: 0)
        encoder.setVertexBuffer(raindropDoubleBuffer, offset: bufferOffset*((doubleBufferIndex+1)%2), index: 1)
        RenderManager.sharedInstance.setGraphicsDataBuffer(encoder, atIndex: 2)
        encoder.setVertexTexture(noiseTexture, index: 0)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleCount, instanceCount: 1)
    }

    func swapBuffers() {
        doubleBufferIndex = (doubleBufferIndex + 1) % 2
    }

}
