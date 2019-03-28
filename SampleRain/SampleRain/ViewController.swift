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
    
    // musica maestro!
    fileprivate var player : AVAudioPlayer?
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.isMotionControllerActive = true
        setupBgm()
        camera.setBounds(view.bounds)
        
        let rain = Rain(numParticles: 2000)
        rain?.queue()
    }
    
    fileprivate func setupBgm() {
        do {
            // Removed deprecated use of AVAudioSessionDelegate protocol
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient, mode: AVAudioSession.Mode.default)
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
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
