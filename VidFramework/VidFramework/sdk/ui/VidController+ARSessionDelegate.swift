//
//  VidController+ARSessionDelegate.swift
//  VidFramework
//
//  Created by David Gavilan on 2019/03/07.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import ARKit

extension VidController: ARSessionDelegate {
    open func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if #available(iOS 12.0, *) {
                if let probe = anchor as? AREnvironmentProbeAnchor,
                    let plugin: ARPlugin? = Renderer.shared?.getPlugin(),
                    let shLight = plugin?.findProbe(identifier: probe.identifier)
                {
                    shLight.environmentTexture = probe.environmentTexture
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }
    open func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    open func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    open func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
}
