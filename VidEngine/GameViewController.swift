//
//  GameViewController.swift
//
//  Created by David Gavilan on 3/31/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import UIKit
import Metal
import MetalKit
import CoreMotion
import AVFoundation
import simd


class GameViewController:UIViewController, MTKViewDelegate {
    
    var device: MTLDevice! = nil
    
    var commandQueue: MTLCommandQueue! = nil
    var timer: CADisplayLink! = nil
    var lastFrameTimestamp: CFTimeInterval = 0.0
    var elapsedTime: CFTimeInterval = 0.0
    let inflightSemaphore = dispatch_semaphore_create(RenderManager.NumSyncBuffers)
    
    // for motion control
    let motionManager = CMMotionManager()
    var currentPitch : Double = 0
    var currentTouch = float2(0, -2)
    var camera = Camera()
    var world : World?
    
    // musica maestro!
    private var player : AVAudioPlayer?

    
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
        
        RenderManager.sharedInstance.initManager(device, view: self.view as! MTKView)
        commandQueue = device.newCommandQueue()
        commandQueue.label = "main command queue"

        timer = CADisplayLink(target: self, selector: #selector(GameViewController.newFrame(_:)))
        timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        
        setupMotionController()
        do {
            // Removed deprecated use of AVAudioSessionDelegate protocol
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
            try AVAudioSession.sharedInstance().setActive(true)
            let music = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("Rain_Background-Mike_Koenig", ofType: "mp3")!)
            player = try AVAudioPlayer(contentsOfURL: music)
            player?.numberOfLoops = -1
            player?.play()
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }
        
        let aspect = Float(view.bounds.width / view.bounds.height)
        camera.setPerspectiveProjection(fov: 45, near: 0.01, far: 120, aspectRatio: aspect)
        camera.transform.position = float3(0, 0, 4)
        world = World(numCubes: 12)
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
    
    private func dataUpdate() {
        RenderManager.sharedInstance.data.elapsedTime = Float(elapsedTime)
        RenderManager.sharedInstance.data.currentPitch = Float(-sin(currentPitch))
        RenderManager.sharedInstance.data.currentTouch = currentTouch
        RenderManager.sharedInstance.data.projectionMatrix = camera.projectionMatrix
        RenderManager.sharedInstance.data.viewMatrix = camera.viewTransformMatrix
    }
    
    func drawInMTKView(view: MTKView) {
        
        // use semaphore to encode 3 frames ahead
        dispatch_semaphore_wait(inflightSemaphore, DISPATCH_TIME_FOREVER)
        
        self.dataUpdate()
        RenderManager.sharedInstance.updateBuffers()
        
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
        RenderManager.sharedInstance.draw(view, commandBuffer: commandBuffer)
    }
    
    
    // Updates the view’s contents upon receiving a change in layout, resolution, or size.
    // Use this method to recompute any view or projection matrices, or to regenerate any buffers to be compatible with the view’s new size.
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        let aspect = Float(view.bounds.width / view.bounds.height)
        camera.setPerspectiveProjection(fov: 45, near: 0.01, far: 120, aspectRatio: aspect)
        let z : Float = aspect >= 1 ? 8 : 4
        camera.transform.position = float3(0, 0, z)
    }
    
    // https://www.raywenderlich.com/81399/ios-8-metal-tutorial-swift-moving-to-3d
    func newFrame(displayLink: CADisplayLink){
        // when using timestamps, the interval switches between 16ms and 33ms, 
        // while the render is always 60fps! Use .duration instead
        elapsedTime = displayLink.duration
        world?.update(elapsedTime)
    }
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        touchesMoved(touches, withEvent: event)
    }
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let overTheFinger : CGFloat = -30
        for t in touches {
            let loc = t.locationInView(view)
            currentTouch.x = 2 * Float(loc.x / view.bounds.width) - 1
            currentTouch.y = 1 - 2 * Float((loc.y + overTheFinger) / view.bounds.height)
        }
    }    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        currentTouch.x = 0
        currentTouch.y = -2
    }
}
