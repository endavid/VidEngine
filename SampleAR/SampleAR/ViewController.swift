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
    var model = ModelOption.sphere
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let cfg = ARWorldTrackingConfiguration()
        cfg.planeDetection = .horizontal
        cfg.environmentTexturing = .manual
        arConfiguration = cfg
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTap(gestureRecognize:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupScene()
    }

    private func setupScene() {
        let cube = CubePrimitive(instanceCount: 1)
        cube.lightingType = .UnlitOpaque
        cube.transform.scale = float3(0.05, 0.05, 0.05)
        scene.cursor = Cursor3D(primitive: cube)
        scene.debugARPlanes = isDebug
    }
    
    @objc
    func handleTap(gestureRecognize: UITapGestureRecognizer) {
        // Create anchor using the camera's current position
        if let session = arSession, let c = scene.cursor, c.intersecting {
            let t = c.transform
            addModel(transform: t)
            addLightProbe(position: t.position + float3(0, 0.25, 0), session: session)
        }
    }
    
    func addModel(transform t: Transform) {
        let tOnGround = Transform(position: t.position + float3(0, 0.05, 0), scale: float3(0.1, 0.1, 0.1), rotation: t.rotation)
        switch model {
        case .cube:
            addCube(transform: tOnGround)
        case .sphere:
            addSphere(transform: tOnGround)
        default:
            let tSmall = Transform(position: t.position, scale: float3(0.1, 0.1, 0.1), rotation: t.rotation)
            addModelFile(model.rawValue, transform: tSmall)
        }
    }
    
    func addCube(transform: Transform) {
        let cube = CubePrimitive(instanceCount: 1)
        cube.transform = transform
        scene.queue(cube)
    }
    
    func addSphere(transform: Transform) {
        let desc = SphereDescriptor(isInterior: false, widthSegments: 16, heightSegments: 16)
        let sphere = SpherePrimitive(instanceCount: 1, descriptor: desc)
        sphere.transform = transform
        scene.queue(sphere)
    }
    
    func addModelFile(_ resource: String, transform: Transform) {
        ModelPrimitive.loadAsync(forResource: resource, withExtension: "json", bundle: Bundle.main) { [weak self] (model, error) in
            if let error = error {
                NSLog(error.localizedDescription)
            }
            if let model = model, let scene = self?.scene {
                model.transform = transform
                scene.queue(model)
            }
        }
    }
    
    func addLightProbe(position: float3, session: ARSession) {
        let extent = float3(0.5, 0.5, 0.5)
        let probe = SHLight(position: position, extent: extent, session: session)
        probe.debug = isDebug ? .sphere : .none
        probe.showBoundingBox = isDebug
        scene.lights.append(probe)
        probe.queue()
    }
}

