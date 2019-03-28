//
//  ViewController.swift
//  SampleText
//
//  Created by David Gavilan on 2018/02/17.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import UIKit
import Metal
import MetalKit
import CoreMotion
import simd
import VidFramework

class ViewController: VidController {
    
    let distanceFromCamera: Float = 2
    var world : World!
    private var cameraAngleX: Float = 0
    private var cameraAngleY: Float = 0
    private var debugCube: CubePrimitive!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        world = World()
        if let cam = world.scene.camera {
            camera = cam
        }
        camera.setBounds(view.bounds)
        scene = world.scene
        
        let tapGest = UITapGestureRecognizer(target: self, action: #selector(ViewController.screenTap(_:)))
        tapGest.numberOfTouchesRequired = 1
        tapGest.numberOfTapsRequired = 2
        view.addGestureRecognizer(tapGest)
        
        debugCube = CubePrimitive(instanceCount: 1)
        debugCube.transform.scale = float3(0.1,0.1,0.1)
        debugCube.queue()
    }
    
    @objc func screenTap(_ sender: UITapGestureRecognizer) {
        let p = sender.location(in: self.view)
        let x = Float(2.0 * p.x / self.view.frame.width - 1.0)
        let y = Float(-2.0 * p.y / self.view.frame.height + 1.0)
        let ray = camera.rayFromScreenCoordinates(x: x, y: y)
        let w = ray.travelDistance(d: distanceFromCamera)
        print("screenTap: \(x),\(y) \(w)")
        debugCube.transform.position = w
    }
}
