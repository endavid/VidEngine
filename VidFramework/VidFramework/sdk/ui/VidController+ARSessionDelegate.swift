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
                    continue
                }
            } else {
                // Fallback on earlier versions
            }
            if let plane = anchor as? ARPlaneAnchor {
                if let (primitive, instanceIndex) = scene.findPrimitiveInstance(by: plane.identifier), let p = primitive as? PlanePrimitive {
                    var t = Transform(rotationAndTranslation: plane.transform)
                    t.scale = simd_float3(plane.extent.x, 1, plane.extent.z)
                    p.instances[instanceIndex].transform = t
                    p.instances[instanceIndex].material.uvScale = Vec2(plane.extent.x / p.gridSizeMeters, plane.extent.z / p.gridSizeMeters)
                }
            } else {
                NSLog("Didn't update anchor: \(anchor.identifier.uuidString)")
            }
        }
    }
    open func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        let arPlanesName = Scene.arPlanesPrimitiveName
        for anchor in anchors {
            if let plane = anchor as? ARPlaneAnchor {
                var t = Transform(rotationAndTranslation: plane.transform)
                t.scale = simd_float3(plane.extent.x, 1, plane.extent.z)
                if let primitive = scene.findPrimitive(by: arPlanesName), let planePrim = primitive as? PlanePrimitive {
                    scene.dequeue(primitive)
                    var instance = Primitive.Instance(transform: t, material: .white, objectId: 0)
                    instance.material.uvScale = Vec2(plane.extent.x / planePrim.gridSizeMeters, plane.extent.z / planePrim.gridSizeMeters)
                    let p = PlanePrimitive(planePrim, add: instance)
                    scene.setupARPlanes(p)
                    p.uuidInstanceMap[plane.identifier] = primitive.instanceCount
                    scene.queue(p, render: scene.debugARPlanes)
                    #if DEBUG
                    print("AR Add \(plane.identifier.uuidString)")
                    #endif
                } else {
                    let p = PlanePrimitive(instanceCount: 1)
                    scene.setupARPlanes(p)
                    p.name = arPlanesName
                    p.transform = t
                    p.instances[0].material.uvScale = Vec2(plane.extent.x / p.gridSizeMeters, plane.extent.z / p.gridSizeMeters)
                    p.uuidInstanceMap[plane.identifier] = 0
                    scene.queue(p, render: scene.debugARPlanes)
                    #if DEBUG
                    print("AR 1st \(plane.identifier.uuidString)")
                    #endif
                }
            }
        }
    }
    open func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            if let plane = anchor as? ARPlaneAnchor {
                if let (primitive, instanceIndex) = scene.findPrimitiveInstance(by: plane.identifier),
                    let planePrim = primitive as? PlanePrimitive {
                    scene.dequeue(primitive)
                    if let p = PlanePrimitive(planePrim, without: instanceIndex) {
                        scene.queue(p, render: scene.debugARPlanes)
                    }
                    #if DEBUG
                    print("AR Removing \(plane.identifier.uuidString)")
                    #endif
                }
            }
        }
    }
    open func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        // Check camera status
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
    open func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
}
