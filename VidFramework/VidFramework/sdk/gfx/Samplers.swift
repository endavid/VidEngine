//
//  Samplers.swift
//  VidFramework
//
//  Created by David Gavilan on 2019/03/19.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import MetalKit

/// Collection of the most common texture samplers
class TextureSamplers {
    enum SamplerType {
        case pointWithClamp, pointWithWrap, linearWithClamp, linearWithWrap
        static let all = [pointWithClamp, pointWithWrap, linearWithClamp, linearWithWrap]
    }
    let samplers: [SamplerType: MTLSamplerState]
    init(device: MTLDevice) {
        var desc: [SamplerType: MTLSamplerDescriptor] = [:]
        for t in SamplerType.all {
            desc[t] = MTLSamplerDescriptor()
            desc[t]?.normalizedCoordinates = true
        }
        // configure samplers
        desc[.pointWithClamp]?.minFilter = .nearest
        desc[.pointWithClamp]?.magFilter = .nearest
        desc[.pointWithClamp]?.mipFilter = .nearest
        desc[.pointWithClamp]?.sAddressMode = .clampToEdge
        desc[.pointWithClamp]?.tAddressMode = .clampToEdge
        desc[.pointWithWrap]?.minFilter = .nearest
        desc[.pointWithWrap]?.magFilter = .nearest
        desc[.pointWithWrap]?.mipFilter = .nearest
        desc[.pointWithWrap]?.sAddressMode = .repeat
        desc[.pointWithWrap]?.tAddressMode = .repeat
        desc[.linearWithClamp]?.minFilter = .linear
        desc[.linearWithClamp]?.magFilter = .linear
        desc[.linearWithClamp]?.mipFilter = .linear
        desc[.linearWithClamp]?.sAddressMode = .clampToEdge
        desc[.linearWithClamp]?.tAddressMode = .clampToEdge
        desc[.linearWithClamp]?.rAddressMode = .clampToEdge
        desc[.linearWithWrap]?.minFilter = .linear
        desc[.linearWithWrap]?.magFilter = .linear
        desc[.linearWithWrap]?.mipFilter = .linear
        desc[.linearWithWrap]?.sAddressMode = .repeat
        desc[.linearWithWrap]?.tAddressMode = .repeat
        // create samplers
        var s: [SamplerType: MTLSamplerState] = [:]
        for t in SamplerType.all {
            guard let d = desc[t], let state = device.makeSamplerState(descriptor: d) else {
                continue
            }
            s[t] = state
        }
        samplers = s
    }
}
