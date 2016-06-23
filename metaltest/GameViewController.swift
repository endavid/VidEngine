//
//  GameViewController.swift
//  metaltest
//
//  Created by David Gavilan on 3/31/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import UIKit
import Metal
import MetalKit

let MaxBuffers = 3
let ConstantBufferSize = 1024*1024


class GameViewController:UIViewController, MTKViewDelegate {
    
    var device: MTLDevice! = nil
    
    var commandQueue: MTLCommandQueue! = nil
    var pipelineState: MTLRenderPipelineState! = nil
    var vertexBuffer: MTLBuffer! = nil
    var vertexColorBuffer: MTLBuffer! = nil
    
    let inflightSemaphore = dispatch_semaphore_create(MaxBuffers)
    var bufferIndex = 0
    
    var vertexCount = 0
    // offsets used in animation
    var xOffset:[Float] = [ -1.0, 1.0, -1.0 ]
    var yOffset:[Float] = [ 1.0, 0.0, -1.0 ]
    var xDelta:[Float] = [ 0.002, -0.001, 0.003 ]
    var yDelta:[Float] = [ 0.001,  0.002, -0.001 ]
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        device = MTLCreateSystemDefaultDevice()
        guard device != nil else { // Fallback to a blank UIView, an application could also fallback to OpenGL ES here.
            print("Metal is not supported on this device")
            self.view = UIView(frame: self.view.frame)
            return
        }

        // setup view properties
        let view = self.view as! MTKView
        view.device = device
        view.delegate = self
        
        loadAssets()
    }
    
    private func loadAssets() {
        
        // load any resources required for rendering
        let view = self.view as! MTKView
        commandQueue = device.newCommandQueue()
        commandQueue.label = "main command queue"
        
        let defaultLibrary = device.newDefaultLibrary()!
        let fragmentProgram = defaultLibrary.newFunctionWithName("passThroughFragment")!
        let vertexProgram = defaultLibrary.newFunctionWithName("passThroughVertex")!
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineStateDescriptor.sampleCount = view.sampleCount
        
        do {
            try pipelineState = device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
        
        // generate a large enough buffer to allow streaming vertices for 3 semaphore controlled frames
        vertexBuffer = device.newBufferWithLength(ConstantBufferSize, options: [])
        vertexBuffer.label = "vertices"
        
        vertexColorBuffer = device.newBufferWithLength(ConstantBufferSize, options: [])
        vertexColorBuffer.label = "colors"
        
        initVertexBuffer(8)
    }
    
    private func initVertexBuffer(numParticles: Int) {
        // vData is pointer to the MTLBuffer's Float data contents
        let pData = vertexBuffer.contents()
        let cData = vertexColorBuffer.contents()
        if numParticles >= 256 {
            vertexCount = 0
            return
        }
        vertexCount = 2 * numParticles
        let vertexSize = 4
        let dropLength : Float = 0.1
        for p in 0..<numParticles {
            let x = 2 * Randf() - 1
            let y = 2 * Randf() - 1
            for i in 0..<MaxBuffers {
                let vDatai = UnsafeMutablePointer<Float>(pData + 256*i)
                let cDatai = UnsafeMutablePointer<Float>(cData + 256*i)
                vDatai[2*vertexSize*p] = x
                vDatai[2*vertexSize*p+1] = y
                vDatai[2*vertexSize*p+2] = 0
                vDatai[2*vertexSize*p+3] = 1
                vDatai[2*vertexSize*p+4] = x
                vDatai[2*vertexSize*p+5] = y + dropLength
                vDatai[2*vertexSize*p+6] = 0
                vDatai[2*vertexSize*p+7] = 1
                cDatai[2*p] = 0.5
                cDatai[2*p+1] = 1.0
            }
        }
        
    }
    
    private func update() {
        
        // vData is pointer to the MTLBuffer's Float data contents
        let pData = vertexBuffer.contents()
        let vData = UnsafeMutablePointer<Float>(pData + 256*bufferIndex)
    }
    
    func drawInMTKView(view: MTKView) {
        
        // use semaphore to encode 3 frames ahead
        dispatch_semaphore_wait(inflightSemaphore, DISPATCH_TIME_FOREVER)
        
        self.update()
        
        let commandBuffer = commandQueue.commandBuffer()
        commandBuffer.label = "Frame command buffer"
        
        // use completion handler to signal the semaphore when this frame is completed allowing the encoding of the next frame to proceed
        // use capture list to avoid any retain cycles if the command buffer gets retained anywhere besides this stack frame
        commandBuffer.addCompletedHandler{ [weak self] commandBuffer in
            if let strongSelf = self {
                dispatch_semaphore_signal(strongSelf.inflightSemaphore)
            }
            return
        }
        
        if let renderPassDescriptor = view.currentRenderPassDescriptor, currentDrawable = view.currentDrawable
        {
            let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
            renderEncoder.label = "render encoder"
            
            renderEncoder.pushDebugGroup("draw morphing triangle")
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 256*bufferIndex, atIndex: 0)
            renderEncoder.setVertexBuffer(vertexColorBuffer, offset:0 , atIndex: 1)
            renderEncoder.drawPrimitives(.Line, vertexStart: 0, vertexCount: vertexCount, instanceCount: 1)
            
            renderEncoder.popDebugGroup()
            renderEncoder.endEncoding()
                
            commandBuffer.presentDrawable(currentDrawable)
        }
        
        // bufferIndex matches the current semaphore controled frame index to ensure writing occurs at the correct region in the vertex buffer
        bufferIndex = (bufferIndex + 1) % MaxBuffers
        
        commandBuffer.commit()
    }
    
    
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}
