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
        let sampler = P3MinusSrgbSampler(bitsPerChannel: 3)
        var samples: [LinearRGBA] = []
        while let s = sampler.getNextSample() {
            samples.append(s)
            let rgb = sampler.p3ToSrgb * s.rgb
            print("\(s.rgb) \(rgb)")
        }
        print(samples.count)
    }
}

