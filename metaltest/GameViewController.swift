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
    var updateState: MTLRenderPipelineState! = nil
    var vertexBuffer: MTLBuffer! = nil
    var vertexColorBuffer: MTLBuffer! = nil
    var uniformBuffer: MTLBuffer! = nil
    var noiseTexture: MTLTexture! = nil
    var timer: CADisplayLink! = nil
    var lastFrameTimestamp: CFTimeInterval = 0.0
    var elapsedTime: CFTimeInterval = 0.0
    let numberOfUniforms = 4 // must be a multiple of 4

    let inflightSemaphore = dispatch_semaphore_create(MaxBuffers)
    var bufferIndex = 0
    
    var vertexCount = 0
    var particleCount = 0
    
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
        timer = CADisplayLink(target: self, selector: #selector(GameViewController.newFrame(_:)))
        timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    private func loadAssets() {
        
        // load any resources required for rendering
        let view = self.view as! MTKView
        commandQueue = device.newCommandQueue()
        commandQueue.label = "main command queue"
        
        let defaultLibrary = device.newDefaultLibrary()!
        let fragmentProgram = defaultLibrary.newFunctionWithName("passThroughFragment")!
        let vertexProgram = defaultLibrary.newFunctionWithName("passThroughVertex")!
        let updateProgram = defaultLibrary.newFunctionWithName("updateRaindrops")!
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineStateDescriptor.sampleCount = view.sampleCount
        
        let updateStateDescriptor = MTLRenderPipelineDescriptor()
        updateStateDescriptor.vertexFunction = updateProgram
        updateStateDescriptor.rasterizationEnabled = false // vertex output is void
        updateStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat // pixel format needs to be set
        
        do {
            try pipelineState = device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
            try updateState = device.newRenderPipelineStateWithDescriptor(updateStateDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
        
        // generate a large enough buffer to allow streaming vertices for 3 semaphore controlled frames
        vertexBuffer = device.newBufferWithLength(ConstantBufferSize, options: [])
        vertexBuffer.label = "vertices"
        
        vertexColorBuffer = device.newBufferWithLength(ConstantBufferSize, options: [])
        vertexColorBuffer.label = "colors"
        
        uniformBuffer = device.newBufferWithLength(sizeof(Float) * numberOfUniforms * MaxBuffers, options: [])
        noiseTexture = createNoiseTexture(device: device, width: 128, height: 128)
        
        initVertexBuffer(200)
    }
    
    private func initVertexBuffer(numParticles: Int) {
        // vData is pointer to the MTLBuffer's Float data contents
        let pData = vertexBuffer.contents()
        let cData = vertexColorBuffer.contents()
        if numParticles >= 256 {
            vertexCount = 0
            return
        }
        particleCount = numParticles
        vertexCount = 2 * numParticles
        let vertexSize = 4
        let dropLength : Float = 0.1
        for p in 0..<numParticles {
            let x = 2 * Randf() - 1
            let y = 1 + 2.4 * Randf()
            let dropSpeed = -0.9 - 0.2 * Randf()
            for i in 0..<MaxBuffers {
                let vDatai = UnsafeMutablePointer<Float>(pData + 256*i)
                let cDatai = UnsafeMutablePointer<Float>(cData + 256*i)
                vDatai[2*vertexSize*p] = x
                vDatai[2*vertexSize*p+1] = y
                vDatai[2*vertexSize*p+2] = 0
                vDatai[2*vertexSize*p+3] = dropSpeed
                vDatai[2*vertexSize*p+4] = x
                vDatai[2*vertexSize*p+5] = y - dropLength
                vDatai[2*vertexSize*p+6] = 0
                vDatai[2*vertexSize*p+7] = dropSpeed
                cDatai[2*p] = 0.5
                cDatai[2*p+1] = 1.0
            }
        }
        
    }
    
    private func update() {
        let uniformB = uniformBuffer.contents()
        let uniformData = UnsafeMutablePointer<Float>(uniformB + numberOfUniforms * bufferIndex);
        uniformData[0] = Float(elapsedTime)
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
            
            renderEncoder.pushDebugGroup("update raindrops")
            renderEncoder.setRenderPipelineState(updateState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 256*bufferIndex, atIndex: 0)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 256*((bufferIndex+1)%MaxBuffers), atIndex: 1)
            renderEncoder.setVertexBuffer(uniformBuffer, offset: numberOfUniforms * bufferIndex, atIndex: 2)
            renderEncoder.setVertexTexture(noiseTexture, atIndex: 0)
            renderEncoder.drawPrimitives(.Point, vertexStart: 0, vertexCount: particleCount, instanceCount: 1)
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
    
    // https://www.raywenderlich.com/81399/ios-8-metal-tutorial-swift-moving-to-3d
    func newFrame(displayLink: CADisplayLink){
        if lastFrameTimestamp == 0.0
        {
            lastFrameTimestamp = displayLink.timestamp
        }
        elapsedTime = displayLink.timestamp - lastFrameTimestamp
        lastFrameTimestamp = displayLink.timestamp
        //gameloop(timeSinceLastUpdate: elapsed)
    }
}
