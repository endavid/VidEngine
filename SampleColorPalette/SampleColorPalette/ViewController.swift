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
import MetalKit
import Photos

class ViewController: VidController {
    var sampler: P3MinusSrgbSampler?
    var samples: [LinearRGBA] = []
    var updateFn: ((TimeInterval) -> ())?
    var framesTilInit = 0
    weak var imageViewP3: UIImageView?
    weak var imageViewSRGB: UIImageView?
    var myFilters: MyFilters?

    override func viewDidLoad() {
        super.viewDidLoad()
        initSprites()
        initTexture()
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
        if myFilters?.isCompleted == true {
            if let mtlTexture = myFilters?.p3TosRgb.chain.last?.output {
                imageViewSRGB?.image = UIImage(texture: mtlTexture)
            }
            if let mtlTexture = myFilters?.p3ToGammaP3.chain.last?.output {
                if let image = UIImage(texture: mtlTexture) {
                    imageViewP3?.image = image
                    //saveImage(image: image)
                }
            }
            Primitive2D.texture = myFilters?.findMinimum.output
            myFilters = nil
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
            initMyFilters(input: mtlTexture)
            if let image = UIImage(texture: mtlTexture) {
                imageViewP3?.image = image
            }
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

    private func initTexture() {
        guard let url = Bundle.main.url(forResource: "iconAbout", withExtension: "png") else {
            return
        }
        let textureLoader = MTKTextureLoader(device: device)
        textureLoader.newTexture(URL: url, options: nil) { (texture, error) in
            Primitive2D.texture = texture
        }
    }
    
    private func createImageView() -> UIImageView {
        let imageView = UIImageView(frame: CGRect())
        imageView.backgroundColor = .clear
        view.addSubview(imageView)
        return imageView
    }
    
    private func initImageViews() {
        self.imageViewP3 = createImageView()
        self.imageViewSRGB = createImageView()
    }
    
    override func viewDidLayoutSubviews() {
        let s: CGFloat = 180
        imageViewP3?.frame = CGRect(x: 0.25 * view.frame.width - 0.5 * s, y: view.frame.height - s - 10, width: s, height: s)
        imageViewSRGB?.frame = CGRect(x: 0.75 * view.frame.width - 0.5 * s, y: view.frame.height - s - 10, width: s, height: s)
    }
    
    private func initMyFilters(input: MTLTexture) {
        guard let m = sampler?.p3ToSrgb else {
            NSLog("Missing sampler")
            return
        }
        let colorTransform = float4x4([
            float4(m[0].x, m[0].y, m[0].z, 0),
            float4(m[1].x, m[1].y, m[1].z, 0),
            float4(m[2].x, m[2].y, m[2].z, 0),
            float4(0, 0, 0, 1),
            ])
        myFilters = MyFilters(device: device, input: input, colorTransform: colorTransform)
    }
    
    func saveImage(image: UIImage) {
        // Perform changes to the library
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }, completionHandler: { success, error in
            if let error = error {
                NSLog(error.localizedDescription)
            }
        })
    }
}

