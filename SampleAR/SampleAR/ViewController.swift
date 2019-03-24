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
            let sphereT = Transform(position: t.position + float3(0, 0.05, 0), scale: float3(0.1, 0.1, 0.1), rotation: t.rotation)
            //addCube(position: t.position)
            addSphere(transform: sphereT)
            addLightProbe(position: t.position + float3(0, 0.25, 0), session: session)
        }
    }
    
    func addCube(position: float3) {
        let cube = CubePrimitive(instanceCount: 1)
        cube.transform.position = position
        cube.transform.scale = float3(0.1, 0.1, 0.1)
        cube.queue()
    }
    
    func addSphere(transform: Transform) {
        let desc = SphereDescriptor(isInterior: false, widthSegments: 8, heightSegments: 8)
        let sphere = SpherePrimitive(instanceCount: 1, descriptor: desc)
        sphere.transform = transform
        sphere.queue()
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

