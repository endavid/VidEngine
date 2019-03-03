//
//  WireCube.swift
//  VidFramework
//
//  Created by David Gavilan on 2019/03/03.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import MetalKit
import simd

public class WireCube: WirePrimitive {
    init(instanceCount: Int) {
        let a = 0.5 * float4(-1, +1, +1, 0)
        let b = 0.5 * float4(-1, +1, -1, 0)
        let c = 0.5 * float4(-1, -1, +1, 0)
        let d = 0.5 * float4(-1, -1, -1, 0)
        let e = 0.5 * float4(+1, +1, +1, 0)
        let f = 0.5 * float4(+1, +1, -1, 0)
        let g = 0.5 * float4(+1, -1, +1, 0)
        let h = 0.5 * float4(+1, -1, -1, 0)
        let lines = [
            Line(start: a, end: b),
            Line(start: a, end: c),
            Line(start: a, end: e),
            Line(start: b, end: d),
            Line(start: b, end: f),
            Line(start: c, end: d),
            Line(start: c, end: g),
            Line(start: d, end: h),
            Line(start: e, end: f),
            Line(start: e, end: g),
            Line(start: f, end: h),
            Line(start: g, end: h),
        ]
        super.init(instanceCount: instanceCount, lines: lines)
    }
}
