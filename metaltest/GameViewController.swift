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
import CoreMotion

// triple buffer so we can update stuff in the CPU while the GPU renders for 3 frames
let NumSyncBuffers = 3

class GameViewController:UIViewController, MTKViewDelegate {
    
    var device: MTLDevice! = nil
    
    var commandQueue: MTLCommandQueue! = nil
    var pipelineState: MTLRenderPipelineState! = nil
    var updateState: MTLRenderPipelineState! = nil
    var raindropDoubleBuffer: MTLBuffer! = nil
    var uniformBuffer: MTLBuffer! = nil
    var noiseTexture: MTLTexture! = nil
    var timer: CADisplayLink! = nil
    var lastFrameTimestamp: CFTimeInterval = 0.0
    var elapsedTime: CFTimeInterval = 0.0
    let maxNumberOfRaindrops = 2048
    let sizeOfLineParticle = sizeof(Float) * 4 * 2
    let numberOfUniforms = 4 // must be a multiple of 4
    let inflightSemaphore = dispatch_semaphore_create(NumSyncBuffers)
    var syncBufferIndex = 0
    var doubleBufferIndex = 0
    
    var vertexCount = 0
    var particleCount = 0
    
    // for motion control
    let motionManager = CMMotionManager()
    var currentPitch : Double = 0
    
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
        
        setupMotionController()
    }
    
    private func setupMotionController() {
        if motionManager.gyroAvailable {
            motionManager.deviceMotionUpdateInterval = 0.2;
            motionManager.startDeviceMotionUpdates()
            
            motionManager.gyroUpdateInterval = 0.2
            if let queue = NSOperationQueue.currentQueue() {
                motionManager.startGyroUpdatesToQueue(queue) {
                    [weak self] (gyroData: CMGyroData?, error: NSError?) in
                    guard let weakSelf = self else { return }
                    if let motion = weakSelf.motionManager.deviceMotion {
                        weakSelf.currentPitch = motion.attitude.pitch
                        //print(motion.attitude)
                    }
                    if error != nil {
                        print("\(error)")
                    }
                }
            }
        }
    }
    
    private func loadAssets() {
        
        // load any resources required for rendering
        let view = self.view as! MTKView
        commandQueue = device.newCommandQueue()
        commandQueue.label = "main command queue"
        
        let defaultLibrary = device.newDefaultLibrary()!
        let fragmentProgram = defaultLibrary.newFunctionWithName("passThroughFragment")!
        let vertexRaindropProgram = defaultLibrary.newFunctionWithName("passVertexRaindrop")!
        let updateRaindropProgram = defaultLibrary.newFunctionWithName("updateRaindrops")!
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexRaindropProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineStateDescriptor.colorAttachments[0].blendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .Add
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .Add
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .SourceAlpha
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .SourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .One
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .OneMinusSourceAlpha
        pipelineStateDescriptor.sampleCount = view.sampleCount
        
        let updateStateDescriptor = MTLRenderPipelineDescriptor()
        updateStateDescriptor.vertexFunction = updateRaindropProgram
        updateStateDescriptor.rasterizationEnabled = false // vertex output is void
        updateStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat // pixel format needs to be set
        
        do {
            try pipelineState = device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
            try updateState = device.newRenderPipelineStateWithDescriptor(updateStateDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
        
        // generate a large enough buffer to allow streaming vertices for 3 semaphore controlled frames
        raindropDoubleBuffer = device.newBufferWithLength(2 * maxNumberOfRaindrops * sizeOfLineParticle, options: [])
        raindropDoubleBuffer.label = "raindrop buffer"
        uniformBuffer = device.newBufferWithLength(sizeof(Float) * numberOfUniforms * NumSyncBuffers, options: [])
        uniformBuffer.label = "uniforms"
        noiseTexture = createNoiseTexture(device: device, width: 128, height: 128)
        
        initVertexBuffer(2000)
    }
    
    private func initVertexBuffer(numParticles: Int) {
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
                let vDatai = UnsafeMutablePointer<Float>(pData + maxNumberOfRaindrops * sizeOfLineParticle * i)
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
    
    private func update() {
        let uniformB = uniformBuffer.contents()
        let uniformData = UnsafeMutablePointer<Float>(uniformB + numberOfUniforms * sizeof(Float) * syncBufferIndex);
        uniformData[0] = Float(elapsedTime)
        uniformData[1] = Float(-sin(currentPitch))
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
            // setVertexBuffer offset: How far the data is from the start of the buffer, in bytes
            // Check alignment in setVertexBuffer doc
            let bufferOffset = maxNumberOfRaindrops * sizeOfLineParticle
            let uniformOffset = numberOfUniforms * sizeof(Float)
            let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
            renderEncoder.label = "render encoder"
            
            renderEncoder.pushDebugGroup("draw morphing triangle")
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(raindropDoubleBuffer, offset: bufferOffset*doubleBufferIndex, atIndex: 0)
            renderEncoder.drawPrimitives(.Line, vertexStart: 0, vertexCount: vertexCount, instanceCount: 1)
            renderEncoder.popDebugGroup()
            
            renderEncoder.pushDebugGroup("update raindrops")
            renderEncoder.setRenderPipelineState(updateState)
            renderEncoder.setVertexBuffer(raindropDoubleBuffer, offset: bufferOffset*doubleBufferIndex, atIndex: 0)
            renderEncoder.setVertexBuffer(raindropDoubleBuffer, offset: bufferOffset*((doubleBufferIndex+1)%2), atIndex: 1)
            renderEncoder.setVertexBuffer(uniformBuffer, offset: uniformOffset * syncBufferIndex, atIndex: 2)
            renderEncoder.setVertexTexture(noiseTexture, atIndex: 0)
            renderEncoder.drawPrimitives(.Point, vertexStart: 0, vertexCount: particleCount, instanceCount: 1)
            renderEncoder.popDebugGroup()

            renderEncoder.endEncoding()
                
            commandBuffer.presentDrawable(currentDrawable)
        }
        
        // syncBufferIndex matches the current semaphore controled frame index to ensure writing occurs at the correct region in the vertex buffer
        syncBufferIndex = (syncBufferIndex + 1) % NumSyncBuffers
        doubleBufferIndex = (doubleBufferIndex + 1) % 2
        
        commandBuffer.commit()
    }
    
    
    // Updates the view’s contents upon receiving a change in layout, resolution, or size.
    // Use this method to recompute any view or projection matrices, or to regenerate any buffers to be compatible with the view’s new size.
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    // https://www.raywenderlich.com/81399/ios-8-metal-tutorial-swift-moving-to-3d
    func newFrame(displayLink: CADisplayLink){
        // when using timestamps, the interval switches between 16ms and 33ms, 
        // while the render is always 60fps! Use .duration instead
        elapsedTime = displayLink.duration
    }
}
