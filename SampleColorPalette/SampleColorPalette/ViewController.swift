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
    weak var imageViewS3: UIImageView?
    weak var imageViewSRGB: UIImageView?
    var filterChain: FilterChain?

    override func viewDidLoad() {
        super.viewDidLoad()
        initSprites()
        camera.setBounds(view.bounds)
        // bits = 7 -> 1039 * 602 samples
        sampler = P3MinusSrgbSampler(bitsPerChannel: 7)
        updateFn = self.updateSamples
        initImageViews()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func update(_ elapsed: TimeInterval) {
        updateFn?(elapsed)
        if filterChain?.isCompleted == true {
            if let mtlTexture = filterChain?.chain.last?.output {
                imageViewSRGB?.image = UIImage(texture: mtlTexture)
            }
            filterChain = nil
        }
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
        let width = 1039
        let height = samples.count / width
        let rgba16data = samples.map { return $0.rgba16U }
        // red = 0xFFFF00000000FFFF, magenta = 0xFFFFFFFF0000FFFF
        // transparent magenta = 0x0000FFFF0000FFFF -> ABGR
        //let rgba16data = [UInt64](repeating: 0xFFFF00000000FFFF, count: samples.count)
        let texture = Texture(device: device, id: "P3-sRGB", width: width, height: height, data: rgba16data)
        if let mtlTexture = texture.mtlTexture {
            Primitive2D.texture = mtlTexture
            imageViewS3?.image = UIImage(texture: mtlTexture)
            initTextureFilter(input: mtlTexture)
        }
    }
    
    private func initSprites() {
        let sprite = SpritePrimitive2D(priority: 0)
        sprite.options = [.alignCenter]
        sprite.position = Vec3(0, 0, 0)
        sprite.width = 320
        sprite.height = 320
        sprite.queue()
    }

    private func createImageView() -> UIImageView {
        let imageView = UIImageView(frame: CGRect())
        imageView.backgroundColor = .clear
        view.addSubview(imageView)
        return imageView
    }
    
    private func initImageViews() {
        self.imageViewS3 = createImageView()
        self.imageViewSRGB = createImageView()
    }
    
    override func viewDidLayoutSubviews() {
        let s: CGFloat = 180
        imageViewS3?.frame = CGRect(x: 0.25 * view.frame.width - 0.5 * s, y: view.frame.height - s - 10, width: s, height: s)
        imageViewSRGB?.frame = CGRect(x: 0.75 * view.frame.width - 0.5 * s, y: view.frame.height - s - 10, width: s, height: s)
    }
    
    private func initTextureFilter(input: MTLTexture) {
        let output = Texture(device: device, id: "sRGB", width: input.width, height: input.height, data: [UInt32].init(repeating: 0, count: input.width * input.height), usage: [.renderTarget, .shaderRead])
        guard let mtlTexture = output.mtlTexture else {
            return
        }
        guard let filter = TextureFilter(id: "toSrgb", input: input, output: mtlTexture, fragmentFunction: "passThroughTexturedFragment") else {
            return
        }
        let chain = FilterChain()
        chain.chain.append(filter)
        chain.queue()
        filterChain = chain
    }
}

