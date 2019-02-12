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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupScene()
    }

    private func setupScene() {
        let cube = CubePrimitive(numInstances: 1)
        cube.transform.position = float3(0, 0, -10)
        cube.queue()
        let sun = DirectionalLight(numInstances: 1)
        sun.color = LinearRGBA(r: 1, g: 0.9, b: 0.8, a: 1.0)
        sun.direction = normalize(float3(1, 1, 1))
        sun.queue()
    }
}

