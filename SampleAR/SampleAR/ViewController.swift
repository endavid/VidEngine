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

    override func viewDidLoad() {
        super.viewDidLoad()
        arConfiguration = ARWorldTrackingConfiguration()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTap(gestureRecognize:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupScene()
    }

    private func setupScene() {
        let cube = CubePrimitive(numInstances: 1)
        cube.transform.position = float3(0, 0, -2)
        cube.transform.scale = float3(0.2, 0.2, 0.2)
        cube.queue()
        let sun = DirectionalLight(numInstances: 1)
        sun.color = LinearRGBA(r: 1, g: 0.9, b: 0.8, a: 1.0)
        sun.direction = normalize(float3(1, 1, 1))
        sun.queue()
    }
    
    @objc
    func handleTap(gestureRecognize: UITapGestureRecognizer) {
        // Create anchor using the camera's current position
        if let currentFrame = arSession?.currentFrame {
            let (_, _, _, pos) = currentFrame.camera.transform.columns
            print(pos)
            //print(currentFrame.camera.transform)
            //print(currentFrame.camera.viewMatrix(for: .landscapeRight))
        }
    }
}

