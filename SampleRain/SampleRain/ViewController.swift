//
//  ViewController.swift
//  SampleRain
//
//  Created by David Gavilan on 2018/02/18.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import AVFoundation
import VidFramework


class ViewController: VidController {
    
    private var cameraAngleX: Float = 0
    private var cameraAngleY: Float = 0
    private var debugCube: CubePrimitive!
    
    // musica maestro!
    fileprivate var player : AVAudioPlayer?
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.isMotionControllerActive = true
        setupBgm()
        camera.setBounds(view.bounds)
        
        let tapGest = UITapGestureRecognizer(target: self, action: #selector(ViewController.screenTap(_:)))
        tapGest.numberOfTouchesRequired = 1
        tapGest.numberOfTapsRequired = 2
        view.addGestureRecognizer(tapGest)
        
        let rain = Rain(numParticles: 2000)
        rain?.queue()
        debugCube = CubePrimitive(numInstances: 1)
        debugCube.transform.scale = float3(0.1,0.1,0.1)
        debugCube.queue()
    }
    
    fileprivate func setupBgm() {
        do {
            // Removed deprecated use of AVAudioSessionDelegate protocol
            try AVAudioSession.sharedInstance().setCategory(convertFromAVAudioSessionCategory(AVAudioSession.Category.ambient))
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
    
    
    @objc func screenTap(_ sender: UITapGestureRecognizer) {
        let p = sender.location(in: self.view)
        let x = Float(2.0 * p.x / self.view.frame.width - 1.0)
        let y = Float(-2.0 * p.y / self.view.frame.height + 1.0)
        let w = camera.worldFromScreenCoordinates(x: x, y: y)
        print("screenTap: \(x),\(y) \(w)")
        debugCube.transform.position = w
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
