//
//  Device.swift
//  VidEngine
//
//  Created by David Gavilan Ruiz on 19/06/2025.
//

import MetalKit

extension MTLDevice {
    var family: String {
        get {
            if self.supportsFamily(.apple9) {
                return "Apple9"
            }
            if self.supportsFamily(.apple8) {
                return "Apple8"
            }
            if self.supportsFamily(.apple7) {
                return "Apple7"
            }
            if self.supportsFamily(.apple6) {
                return "Apple6"
            }
            if self.supportsFamily(.apple5) {
                return "Apple5"
            }
            if self.supportsFamily(.apple4) {
                return "Apple4"
            }
            if self.supportsFamily(.apple3) {
                return "Apple3"
            }
            if self.supportsFamily(.apple2) {
                return "Apple2"
            }
            if self.supportsFamily(.apple1) {
                return "Apple1"
            }
            if #available(macOS 13.0, iOS 16.0, *) {
                if self.supportsFamily(.metal3) {
                    return "Metal3"
                }
            } else {
                // Fallback on earlier versions
            }
            if self.supportsFamily(.common3) {
                return "Common3"
            }
            if self.supportsFamily(.common2) {
                return "Common2"
            }
            if self.supportsFamily(.common1) {
                return "Common1"
            }
            if self.supportsFamily(.mac2) {
                return "Mac2"
            }
            return "Unknown"
        }
    }
}
