//
//  ColorSampler.swift
//  SampleColorPalette
//
//  Created by David Gavilan on 2018/02/24.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import VidFramework
import simd

protocol ColorSampler {
    func getNextSample() -> LinearRGBA?
}

class P3MinusSrgbSampler: ColorSampler {
    let p3ToSrgb: float3x3
    private let size: Int
    private let toNormal: Float
    private var i: Int = 0
    private var j: Int = 0
    private var k: Int = 0

    var volume: Int {
        get {
            return size * size * size
        }
    }

    func getNextSample() -> LinearRGBA? {
        var sample: float3?
        while i < size && j < size && k < size && sample == nil {
            sample = getNext()
            advanceIndices()
        }
        if let sample = sample {
            return LinearRGBA(rgb: sample)
        }
        return nil
    }

    private func getNext() -> float3? {
        let p3 = toRgb(i, j, k)
        let srgb = p3ToSrgb * p3
        if !srgb.inUnitCube() {
            return p3
        }

        return nil
    }

    private func toRgb(_ a: Int, _ b: Int, _ c: Int) -> float3 {
        return float3(Float(a), Float(b), Float(c)) * toNormal
    }

    private func advanceIndices() {
        k += 1
        if k >= size {
            k = 0
            j += 1
            if j >= size {
                j = 0
                i += 1
            }
        }
    }

    init(bitsPerChannel: UInt8) {
        size = 1 << bitsPerChannel
        toNormal = 1 / Float(size-1)
        p3ToSrgb = RGBColorSpace.sRGB.toRGB * RGBColorSpace.dciP3.toXYZ
    }
}
