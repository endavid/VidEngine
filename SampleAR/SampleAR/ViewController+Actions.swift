//
//  ViewController+Actions.swift
//  SampleAR
//
//  Created by David Gavilan on 2019/03/24.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import VidFramework

extension ViewController {
    @IBAction func toggleDebugging() {
        if isDebug {
            scene.debugARPlanes = false
            setSHDebugMode(.none)
        } else {
            scene.debugARPlanes = true
            setSHDebugMode(.sphere)
        }
        isDebug = !isDebug
    }
    
    func setSHDebugMode(_ mode: SHLight.DebugMode) {
        scene.lights.forEach { (lightSource) in
            if let probe = lightSource as? SHLight {
                probe.debug = mode
                probe.showBoundingBox = mode == SHLight.DebugMode.none ? false : true
            }
        }
    }
}
