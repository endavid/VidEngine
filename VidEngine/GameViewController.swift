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
    var elapsedTimeGPU: CFTimeInterval = 0.0
    let inflightSemaphore = DispatchSemaphore(value: RenderManager.NumSyncBuffers)
    
    // for motion control
    let motionManager = CMMotionManager()
    var currentPitch : Double = 0
    var currentTouch = float2(0, -2)
    var world : World?
    
    var camera : Camera {
        get {
            return RenderManager.sharedInstance.camera
        }
        set {
            RenderManager.sharedInstance.camera = newValue
        }
    }
    
    // musica maestro!
    fileprivate var player : AVAudioPlayer?

    
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
        // our shaders will be in linear RGB, so automatically apply γ
        view.colorPixelFormat = .bgra8Unorm_srgb
        
        RenderManager.sharedInstance.initManager(device, view: self.view as! MTKView)
        commandQueue = device.makeCommandQueue()
        commandQueue.label = "main command queue"

        timer = CADisplayLink(target: self, selector: #selector(GameViewController.newFrame(_:)))
        timer.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
        
        setupMotionController()
        //setupBgm()
        
        world = World()
        if let cam = world?.scene.camera {
            camera = cam
        }
        camera.setBounds(view.bounds)
    }
    
    fileprivate func setupBgm() {
        do {
            // Removed deprecated use of AVAudioSessionDelegate protocol
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
            try AVAudioSession.sharedInstance().setActive(true)
            let music = URL(fileURLWithPath: Bundle.main.path(forResource: "Rain_Background-Mike_Koenig", ofType: "mp3")!)
            player = try AVAudioPlayer(contentsOf: music)
            player?.numberOfLoops = -1
            player?.play()
        }
        catch let error {
            NSLog("setupBgm: \(error.localizedDescription)")
        }
    }
    
    fileprivate func setupMotionController() {
        if motionManager.isGyroAvailable {
            motionManager.deviceMotionUpdateInterval = 0.2;
            motionManager.startDeviceMotionUpdates()
            
            motionManager.gyroUpdateInterval = 0.2
            if let queue = OperationQueue.current {
                motionManager.startGyroUpdates()
                motionManager.startGyroUpdates(to: queue) {
                    [weak self] (gyroData: CMGyroData?, error: Error?) in
                    guard let weakSelf = self else { return }
                    if let motion = weakSelf.motionManager.deviceMotion {
                        weakSelf.currentPitch = motion.attitude.pitch
                        //print(motion.attitude)
                    }
                    if let error = error {
                        NSLog("setupMotionController: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    fileprivate func dataUpdate() {
        RenderManager.sharedInstance.graphicsData.elapsedTime = Float(elapsedTimeGPU)
        RenderManager.sharedInstance.graphicsData.currentPitch = Float(-sin(currentPitch))
        RenderManager.sharedInstance.graphicsData.currentTouch = currentTouch
    }
    
    func draw(in view: MTKView) {
        
        // use semaphore to encode 3 frames ahead
        let _ = inflightSemaphore.wait(timeout: DispatchTime.distantFuture)
        // could check here for .timedOut to count number of skipped frames
        
        self.dataUpdate()
        RenderManager.sharedInstance.updateBuffers()
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        commandBuffer.label = "Frame command buffer"
        
        // use completion handler to signal the semaphore when this frame is completed allowing the encoding of the next frame to proceed
        // use capture list to avoid any retain cycles if the command buffer gets retained anywhere besides this stack frame
        commandBuffer.addCompletedHandler{ [weak self] commandBuffer in
            if let strongSelf = self {
                strongSelf.inflightSemaphore.signal()
            }
            return
        }        
        RenderManager.sharedInstance.draw(view, commandBuffer: commandBuffer)
    }
    
    
    // Updates the view’s contents upon receiving a change in layout, resolution, or size.
    // Use this method to recompute any view or projection matrices, or to regenerate any buffers to be compatible with the view’s new size.
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        camera.setBounds(view.bounds)
    }
        
    // https://www.raywenderlich.com/81399/ios-8-metal-tutorial-swift-moving-to-3d
    func newFrame(_ displayLink: CADisplayLink){
        if lastFrameTimestamp == 0.0 {
            lastFrameTimestamp = displayLink.timestamp
        }
        let elapsed = displayLink.timestamp - lastFrameTimestamp
        // when using timestamps, the interval switches between 16ms and 33ms,
        // while the render is always 60fps! Use .duration for GPU updates
        elapsedTimeGPU = displayLink.duration
        lastFrameTimestamp = displayLink.timestamp
        world?.update(elapsed)
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesMoved(touches, with: event)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let overTheFinger : CGFloat = -30
        for t in touches {
            let loc = t.location(in: view)
            currentTouch.x = 2 * Float(loc.x / view.bounds.width) - 1
            currentTouch.y = 1 - 2 * Float((loc.y + overTheFinger) / view.bounds.height)
        }
    }    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentTouch.x = 0
        currentTouch.y = -2
    }
}
