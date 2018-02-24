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
    private var c1: Float
    private var c2: Float
    private var c3: Float
    private enum Order: Int {
        case
        belowRed = 0,
        aboveRed,
        belowGreen,
        aboveGreen,
        belowBlue,
        aboveBlue
    }
    private var order: Order? = .belowRed
    private var ref: Float?
    
    func getNextSample() -> LinearRGBA? {
        var sample: float3?
        repeat {
            sample = getNext()
        } while order != nil && sample == nil
        if let sample = sample {
            return LinearRGBA(rgb: sample)
        }
        return nil
    }
    
    private func getNext() -> float3? {
        guard let o = order else {
            return nil
        }
        let isBelow = (o.rawValue % 2) == 0
        let value = isBelow ? getNextBelow() : getNextAbove()
        guard let rgb = value else {
            return nil
        }
        if o == .belowGreen || o == .aboveGreen {
            return float3(rgb.x, rgb.z, rgb.y)
        } else if o == .belowBlue || o == .aboveBlue {
            return float3(rgb.z, rgb.x, rgb.y)
        }
        return rgb
    }
    
    private func getNextBelow() -> float3? {
        let rgb = toRgb(i, j, k)
        let bMax = ref ?? (c1 * rgb.x + c2 * rgb.y) / (-c3)
        if k >= size || rgb.z >= bMax {
            advanceIndices()
            return nil
        }
        print("\(rgb) \(bMax)")
        k += 1
        return rgb
    }
    private func getNextAbove() -> float3? {
        let rgb = toRgb(i, j, size - 1 - k)
        let bMin = ref ?? (1 - c1 * rgb.x - c2 * rgb.y) / c3
        if k <= 0 || rgb.z <= bMin {
            advanceIndices()
            return nil
        }
        print("\(rgb) \(bMin)")
        k += 1
        return rgb
    }

    private func toRgb(_ a: Int, _ b: Int, _ c: Int) -> float3 {
        return float3(Float(a), Float(b), Float(c)) * toNormal
    }
    
    private func advanceIndices() {
        k = 0
        ref = nil
        i += 1
        if i >= size {
            i = 0
            j += 1
            if j >= size {
                j = 0
                if let o = order {
                    order = Order(rawValue: o.rawValue + 1)
                    let channel = 2 - (order?.rawValue ?? 0) / 2
                    c1 = p3ToSrgb[0][channel]
                    c2 = p3ToSrgb[1][channel]
                    c3 = p3ToSrgb[2][channel]
                }
            }
        }
    }
    
    init(bitsPerChannel: UInt8) {
        size = 1 << bitsPerChannel
        toNormal = 1 / Float(size-1)
        p3ToSrgb = RGBColorSpace.dciP3.toRGB * RGBColorSpace.sRGB.toXYZ
        print(p3ToSrgb)
        c1 = p3ToSrgb[0][2]
        c2 = p3ToSrgb[1][2]
        c3 = p3ToSrgb[2][2]
        print(c1)
        print(c2)
        print(c3)
    }
}
