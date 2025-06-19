//
//  VidController.swift
//  VidEngine
//
//  Created by David Gavilan Ruiz on 19/06/2025.
//
#if canImport(UIKit)
import UIKit
public typealias ViewController = UIViewController
#else
import AppKit
public typealias ViewController = NSViewController
#endif
import Metal
import MetalKit
import AVFoundation
import simd

@available(macOS 14.0, iOS 10.0, *)
open class VidController: ViewController, MTKViewDelegate {
    public var device: MTLDevice! = nil
    
    var renderer: Renderer!
    var commandQueue: MTLCommandQueue! = nil
    // in macOS 13.0 or earlier, we could use CVDisplayLink instead
    var timer: CADisplayLink! = nil
    var lastFrameTimestamp: TimeInterval = 0.0
    var elapsedTimeGPU: TimeInterval = 0.0
    let inflightSemaphore = DispatchSemaphore(value: 0)
    private var currentTouch = simd_float2(0, -2)
    private var cameraAngleX: Float = 0
    private var cameraAngleY: Float = 0
    private var debugCube: CubePrimitive!
    private var _clearColor = UIColor.black
    private var motionController: MotionController?
    //public var scene = Scene()
    public var arConfiguration: ARConfiguration?
    
    public var clearColor: UIColor {
        get {
            return _clearColor
        }
        set {
            _clearColor = newValue
            let c = LinearRGBA(newValue)
            renderer.clearColor = MTLClearColor(red: Double(c.r), green: Double(c.g), blue: Double(c.b), alpha: Double(c.a))
        }
    }
    public var camera: Camera {
        get {
            return renderer.camera
        }
        set {
            renderer.camera = newValue
        }
    }
    public var isWideColor = false {
        didSet {
            if let view = self.view as? MTKView {
                // The pixel format for a MetalKit view must be bgra8Unorm, bgra8Unorm_srgb, rgba16Float, BGRA10_XR, or bgra10_XR_sRGB.
                // our shaders will be in linear RGB, so automatically apply γ
                view.colorPixelFormat = isWideColor ? .bgra10_xr_srgb : .bgra8Unorm_srgb
            }
        }
    }
    public var isMotionControllerActive: Bool {
        get {
            return motionController != nil
        }
        set {
            let current = motionController != nil
            if current != newValue {
                if newValue {
                    motionController = MotionController()
                } else {
                    motionController = nil
                }
            }
        }
    }
    public var isAREnabled: Bool {
        get {
            return renderer.arSession != nil
        }
    }
    public var arSession: ARSession? {
        get {
            return renderer.arSession
        }
    }
    public var textureLibrary: TextureLibrary {
        get {
            return renderer.textureLibrary
        }
    }
    
    open override func viewDidLoad() {
        
        super.viewDidLoad()
        
        device = MTLCreateSystemDefaultDevice()
        guard device != nil else { // Fallback to a blank UIView, an application could also fallback to OpenGL ES here.
            NSLog("Metal is not supported on this device")
            return
        }
        
        // setup view properties
        let view = self.view as! MTKView
        view.device = device
        view.delegate = self
        isWideColor = true
        
        commandQueue = device.makeCommandQueue()
        commandQueue.label = "main command queue"
    }
    
    #if canImport(UIKit)
    override open func viewWillAppear(_ animated: Bool) {
        initRenderer()
    }
    override open func viewWillDisappear(_ animated: Bool) {
        destroyRenderer()
    }
    #else
    override open func viewWillAppear() {
        initRenderer()
    }
    override open func viewWillDisappear() {
        destroyRenderer()
    }
    #endif


    private func initRenderer() {
        if device == nil {
            return
        }
        if renderer == nil {
            // already added in viewDidLoad, but if we dismissed the view and present it again, this will be necessary
            let view = self.view as! MTKView
            do {
                renderer = try Renderer(view: view, doAR: arConfiguration != nil)
                // init with 0 and send 3 signals on init to fix crash when closing window
                // https://forums.developer.apple.com/forums/thread/126781
                // https://lists.apple.com/archives/cocoa-dev/2014/Apr/msg00485.html
                for _ in 0..<Renderer.numSyncBuffers {
                    inflightSemaphore.signal()
                }
                #if os(macOS)
                timer = view.displayLink(target: self, selector: #selector(VidController.newFrame(_:)))
                #else
                timer = CADisplayLink(target: self, selector: #selector(VidController.newFrame(_:)))
                #endif
                timer.add(to: RunLoop.main, forMode: RunLoop.Mode.default)
                camera.setBounds(view.bounds)
                camera.rotation = Quaternion()
            } catch {
                NSLog(error.localizedDescription)
            }
        }
        if let arConfiguration = arConfiguration {
            arSession?.run(arConfiguration)
            arSession?.delegate = self
            clearColor = .clear
        } else {
            clearColor = UIColor(red: 48/255, green: 45/255, blue: 45/255, alpha: 1)
        }
    }
    
    private func destroyRenderer() {
        guard let renderer = renderer else {
            return
        }
        renderer.arSession?.pause()
        NotificationCenter.default.removeObserver(self)
        timer.remove(from: .main, forMode: RunLoop.Mode.default)
        timer = nil
        self.renderer = nil
        inflightSemaphore.signal()
    }
    
    private func dataUpdate(_ renderer: Renderer) {
        renderer.graphicsData.elapsedTime = Float(elapsedTimeGPU)
        renderer.graphicsData.currentPitch = 0
        renderer.graphicsData.currentTouch = currentTouch
        if let pitch = motionController?.currentPitch {
            renderer.graphicsData.currentPitch = Float(-sin(pitch))
        }
        if let frame = renderer.arSession?.currentFrame {
            updateArCamera(frame)
        }
    }
    
    private func updateArCamera(_ frame: ARFrame) {
        //let (_,_,_, pos) = frame.camera.transform.columns
        //camera.transform.position = pos.xyz
        if camera.orientation.isLandscape {
            camera.transform = Transform(rotationAndTranslation: frame.camera.transform)
        } else {
            let viewMatrix = frame.camera.viewMatrix(for: camera.orientation)
            camera.transform = Transform(rotationAndTranslation: viewMatrix.inverse)
        }
        camera.projection = frame.camera.projectionMatrix(for: camera.orientation, viewportSize: view.bounds.size, zNear: CGFloat(camera.near), zFar: CGFloat(camera.far))
    }
    
    public func draw(in view: MTKView) {
        guard let renderer = self.renderer else {
            return
        }
        // use semaphore to encode 3 frames ahead
        let _ = inflightSemaphore.wait(timeout: DispatchTime.distantFuture)
        // could check here for .timedOut to count number of skipped frames
        
        dataUpdate(renderer)
        renderer.updateBuffers()
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            logDebug("Failed to create command buffer")
            return
        }
        commandBuffer.label = "Frame command buffer"
        
        // use completion handler to signal the semaphore when this frame is completed allowing the encoding of the next frame to proceed
        // use capture list to avoid any retain cycles if the command buffer gets retained anywhere besides this stack frame
        var textures = [renderer.capturedImageTextureY, renderer.capturedImageTextureCbCr]
        commandBuffer.addCompletedHandler{ [weak self] cb in
            if let strongSelf = self {
                strongSelf.inflightSemaphore.signal()
            }
            textures.removeAll()
        }
        renderer.draw(view, commandBuffer: commandBuffer)
    }
    
    // Updates the view’s contents upon receiving a change in layout, resolution, or size.
    // Use this method to recompute any view or projection matrices, or to regenerate any buffers to be compatible with the view’s new size.
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        camera.setBounds(view.bounds)
    }
    
    // https://www.raywenderlich.com/81399/ios-8-metal-tutorial-swift-moving-to-3d
    @objc func newFrame(_ displayLink: CADisplayLink){
        if lastFrameTimestamp == 0.0 {
            lastFrameTimestamp = displayLink.timestamp
        }
        let elapsed = displayLink.timestamp - lastFrameTimestamp
        // when using timestamps, the interval switches between 16ms and 33ms,
        // while the render is always 60fps! Use .duration for GPU updates
        elapsedTimeGPU = displayLink.duration
        lastFrameTimestamp = displayLink.timestamp
        self.update(elapsed)
    }
    
    open func update(_ elapsed: TimeInterval) {
        //scene.update(elapsed, camera: camera)
    }
}
