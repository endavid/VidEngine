//
//  MotionController.swift
//  VidFramework
//
//  Created by David Gavilan on 2018/08/18.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import Foundation
import CoreMotion

class MotionController {
    private let motionManager = CMMotionManager()
    private var _currentPitch: Double = 0
    
    public var currentPitch: Double {
        get {
            return _currentPitch
        }
    }
    
    init() {
        if motionManager.isGyroAvailable {
            motionManager.deviceMotionUpdateInterval = 0.2;
            motionManager.startDeviceMotionUpdates()
            
            motionManager.gyroUpdateInterval = 0.2
            if let queue = OperationQueue.current {
                motionManager.startGyroUpdates()
                motionManager.startGyroUpdates(to: queue) {
                    [weak self] (gyroData: CMGyroData?, error: Error?) in
                    guard let weakSelf = self else { return }
                    if let motion = weakSelf.motionManager.deviceMotion {
                        weakSelf._currentPitch = motion.attitude.pitch
                    }
                    if let error = error {
                        NSLog("setupMotionController: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
