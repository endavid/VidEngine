//
//  ViewController+Actions.swift
//  SampleAR
//
//  Created by David Gavilan on 2019/03/24.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import VidFramework

extension ViewController {
    func setDebugging(_ isOn: Bool) {
        if isOn {
            scene.debugARPlanes = true
            setSHDebugMode(.sphere)
        } else {
            scene.debugARPlanes = false
            setSHDebugMode(.none)
        }
        isDebug = isOn
    }
    
    func setSHDebugMode(_ mode: SHLight.DebugMode) {
        scene.lights.forEach { (lightSource) in
            if let probe = lightSource as? SHLight {
                probe.debug = mode
                probe.showBoundingBox = mode == SHLight.DebugMode.none ? false : true
            }
        }
    }
    
    /// - Tag: restartExperience
    func restartExperience() {
        guard isRestartAvailable, !isLoading else { return }
        isRestartAvailable = false
        
        statusViewController.cancelAllScheduledMessages()
        
        scene.removeAll()
        resetTracking()
        
        // Disable restart for a while in order to give the session time to restart.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.isRestartAvailable = true
        }
    }
}
