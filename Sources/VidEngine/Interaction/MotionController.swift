//
//  MotionController.swift
//  VidEngine
//
//  Created by David Gavilan Ruiz on 19/06/2025.
//
import Foundation
import CoreMotion
#if os(macOS)
class MockMotionManager {
    var isGyroAvailable = false
    var deviceMotionUpdateInterval: Float = 0
    var gyroUpdateInterval: Float = 0
    var deviceMotion: CMDeviceMotion?
    
    func startDeviceMotionUpdates() {
        logDebug("CMMotionManager unavailable: startDeviceMotionUpdates()")
    }
    func startGyroUpdates() {
        logDebug("CMMotionManager unavailable: startGyroUpdates()")
    }
    func startGyroUpdates(to: OperationQueue, withHandler handler: @escaping CMGyroHandler) {
        logDebug("CMMotionManager unavailable: startGyroUpdates()")
    }
}
typealias CMMotionManager = MockMotionManager
#endif


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
