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
    var sampler: P3MinusSrgbSampler?
    var samples: [LinearRGBA] = []
    var updateFn: ((TimeInterval) -> ())?
    var framesTilInit = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // bits = 7 -> 1039 * 602 samples
        sampler = P3MinusSrgbSampler(bitsPerChannel: 7)
        updateFn = self.updateSamples
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func update(_ elapsed: TimeInterval) {
        updateFn?(elapsed)
    }
    
    private func updateSamples(_ elapsed: TimeInterval) {
        let start = DispatchTime.now()
        let choppyFramerate = 2 * elapsed
        var outOfTime = false
        while let p3 = sampler?.getNextSample(), !outOfTime {
            samples.append(p3)
            let nanoTime = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
            let timeInterval = Double(nanoTime) / 1_000_000_000
            outOfTime = timeInterval > choppyFramerate
        }
        if !outOfTime {
            // done!
            didInitSamples()
            updateFn = nil
        }
        framesTilInit += 1
    }
    
    private func didInitSamples() {
        let ratio = (100 * Float(samples.count) / Float(sampler?.volume ?? 0)).rounded(toPlaces: 4)
        print("#samples: \(samples.count); \(ratio)% of the P3 space not covered by sRGB")
        print("-- Computed in \(framesTilInit) frames")
    }
}

