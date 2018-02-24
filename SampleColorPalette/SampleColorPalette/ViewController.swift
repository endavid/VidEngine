//
//  ViewController.swift
//  SampleColorPalette
//
//  Created by David Gavilan on 2018/02/24.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import UIKit
import VidFramework
import simd

class ViewController: VidController {

    override func viewDidLoad() {
        super.viewDidLoad()
        initSamples()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func initSamples() {
        // bits = 7 -> 1039 * 602 samples
        let sampler = P3MinusSrgbSampler(bitsPerChannel: 7)
        var samples: [LinearRGBA] = []
        var countPerChannel = int3(0,0,0)
        while let p3 = sampler.getNextSample() {
            samples.append(p3)
            let srgb = sampler.p3ToSrgb * p3.rgb
            if srgb.x < 0 || srgb.x > 1 {
                countPerChannel.x += 1
            }
            if srgb.y < 0 || srgb.y > 1 {
                countPerChannel.y += 1
            }
            if srgb.z < 0 || srgb.z > 1 {
                countPerChannel.z += 1
            }
        }
        let ratio = (100 * Float(samples.count) / Float(sampler.volume)).rounded(toPlaces: 4)
        print("#samples: \(samples.count); \(ratio)% of the P3 space not covered by sRGB")
        print("count: \(countPerChannel)")
    }
}

