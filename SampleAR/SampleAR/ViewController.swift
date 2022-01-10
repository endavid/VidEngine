//
//  ViewController.swift
//  SampleAR
//
//  Created by David Gavilan on 2018/08/19.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import UIKit
import VidFramework
import ARKit

class ViewController: VidController {
    var isDebug = false
    var isGlobalLight = false
    var localSHLightSize: Float = 0.5
    var model = ModelOption.sphere
    /// Marks if the AR experience is available for restart.
    var isRestartAvailable = true
    /// True when loading a model
    var isLoading = false
    @IBOutlet weak var blurView: UIVisualEffectView!

    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return children.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let cfg = ARWorldTrackingConfiguration()
        cfg.planeDetection = .horizontal
        cfg.environmentTexturing = .manual
        arConfiguration = cfg
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTap(gestureRecognize:)))
        view.addGestureRecognizer(tapGesture)
        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupScene()
    }
    
    /// Creates a new AR configuration to run on the `session`.
    func resetTracking() {
        guard let session = arSession, let cfg = arConfiguration else {
            return
        }
        session.run(cfg, options: [.resetTracking, .removeExistingAnchors])        
        statusViewController.scheduleMessage("FIND A SURFACE TO PLACE AN OBJECT", inSeconds: 7.5, messageType: .planeEstimation)
    }

    private func setupScene() {
        let plane = PlanePrimitive(instanceCount: 1)
        plane.lightingType = .UnlitTransparent
        plane.name = "cursorPlane"
        plane.transform.scale = simd_float3(0.1, 1, 0.1)
        plane.material.diffuse = .white
        if let bundle = try? FrameworkBundle.mainBundle() {
            plane.setAlbedoTexture(resource: FrameworkBundle.squareFrameImage, bundle: bundle, options: nil, addToCache: true) { (error) in
                if let error = error {
                    NSLog("setupScene: \(error.localizedDescription)")
                }
            }
            plane.sampler = .pointWithWrap
        }
        scene.cursor = Cursor3D(primitive: plane)
        scene.debugARPlanes = isDebug
    }
    
    @objc
    func handleTap(gestureRecognize: UITapGestureRecognizer) {
        // Create anchor using the camera's current position
        if let session = arSession, let c = scene.cursor, c.intersecting {
            let t = c.transform
            addModel(transform: t)
            let offsetY: Float = isGlobalLight ? 1.2 : (localSHLightSize / 2)
            addLightProbe(position: t.position + simd_float3(0, offsetY, 0), session: session)
            addAnchor(session: session, transform: t)
        }
    }
    
    func addAnchor(session: ARSession, transform t: Transform) {
        let tAnchor = Transform(position: t.position, scale: simd_float3(1,1,1), rotation: t.rotation)
        // Create a new anchor with the object's current transform and add it to the session
        let newAnchor = ARAnchor(transform: tAnchor.toMatrix4())
        session.add(anchor: newAnchor)
    }
    
    func addModel(transform t: Transform) {
        let tOnGround = Transform(position: t.position + simd_float3(0, 0.05, 0), scale: simd_float3(0.1, 0.1, 0.1), rotation: t.rotation)
        switch model {
        case .cube:
            addCube(transform: tOnGround)
        case .sphere:
            addSphere(transform: tOnGround)
        default:
            let tNormalSize = Transform(position: t.position, scale: .one, rotation: t.rotation)
            addModelFile(model.rawValue, transform: tNormalSize)
        }
    }
    
    func addCube(transform: Transform) {
        let cube = CubePrimitive(instanceCount: 1)
        cube.transform = transform
        cube.name = "cube"
        scene.queue(cube)
    }
    
    func addSphere(transform: Transform) {
        let desc = SphereDescriptor(isInterior: false, widthSegments: 16, heightSegments: 16)
        let sphere = SpherePrimitive(instanceCount: 1, descriptor: desc)
        sphere.transform = transform
        sphere.name = "sphere"
        scene.queue(sphere)
    }
    
    func addModelFile(_ resource: String, transform: Transform) {
        isLoading = true
        ModelPrimitive.loadAsync(forResource: resource, withExtension: "json", bundle: Bundle.main) { [weak self] (model, error) in
            self?.isLoading = false
            if let error = error {
                NSLog(error.localizedDescription)
            }
            if let model = model, let scene = self?.scene {
                model.transform = transform
                scene.queue(model)
            }
        }
    }
    
    func addLightProbe(position: simd_float3, session: ARSession) {
        let extent = (isGlobalLight ? Float.infinity : localSHLightSize) * simd_float3.one
        let probe = SHLight(position: position, extent: extent, session: session)
        probe.debug = isDebug ? .sphere : .none
        probe.showBoundingBox = isDebug
        scene.queue(probe)
    }
    
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // Blur the background.
        blurView.isHidden = false
        
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.blurView.isHidden = true
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
}

