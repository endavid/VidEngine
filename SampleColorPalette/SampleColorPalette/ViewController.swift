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
        let sampler = P3MinusSrgbSampler(bitsPerChannel: 4)
        var samples: [LinearRGBA] = []
        while let p3 = sampler.getNextSample() {
            samples.append(p3)
            let srgb = sampler.p3ToSrgb * p3.rgb
            print("\(p3.rgb) \(srgb)")
        }
        let ratio = (100 * Float(samples.count) / Float(sampler.volume)).rounded(toPlaces: 4)
        print("#samples: \(samples.count); \(ratio)% of the P3 space not covered by sRGB")
    }
}

