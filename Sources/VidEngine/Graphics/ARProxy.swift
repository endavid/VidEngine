//
//  ARProxy.swift
//  VidEngine
//
//  Created by David Gavilan Ruiz on 19/06/2025.
//
#if canImport(ARKit)
import ARKit
#else
import Foundation
import simd
public typealias ARConfiguration = String

protocol ARSessionDelegate {
    
}

public class ARMockCamera {
    var transform = simd_float4x4()
    var projectionMatrix = simd_float4x4()
    func projectionMatrix(
        for orientation: UIInterfaceOrientation,
        viewportSize: CGSize,
        zNear: CGFloat,
        zFar: CGFloat
    ) -> simd_float4x4 {
        return simd_float4x4()
    }
    
    func viewMatrix(for orientation: UIInterfaceOrientation) -> simd_float4x4 {
        return simd_float4x4()
    }
}

public class ARMockFrame {
    var camera = ARMockCamera()
}

public class ARMockSession {
    private var setCount = 0
    var currentFrame: ARMockFrame?
    var delegate: Any {
        get {
            return setCount
        }
        set {
            // let's count the number of times it's set
            setCount += 1
        }
    }
    func run(_ config: ARConfiguration) {
        logDebug("ARKit not available: run(\(config))")
    }
    func pause() {
        logDebug("ARKit not available: pause()")
    }
}
public typealias ARSession = ARMockSession
public typealias ARFrame = ARMockFrame
#endif
