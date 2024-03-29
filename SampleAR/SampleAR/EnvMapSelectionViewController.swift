//
//  EnvMapSelectionViewController.swift
//  SampleAR
//
//  Created by David Gavilan on 02/12/2021.
//  Copyright © 2021 David Gavilan. All rights reserved.
//

import UIKit
import VidFramework

class EnvMapSelectionViewController: UIViewController {
        
    @IBOutlet weak var scrollView: UIScrollView!
    
    let margin: CGFloat = 10
    private var maxHeight : CGFloat = 0
    private var probeCount = 0
    
    override func viewWillLayoutSubviews() {
        logFunctionName()
    }
    override func viewDidLayoutSubviews() {
        logFunctionName()
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: maxHeight)
    }
    override func viewWillAppear(_ animated: Bool) {
        if let vid = self.presentingViewController as? VidController {
            let probes = vid.scene.lights.compactMap { $0 as? SHLight }
            for p in probes {
                let button = createButton(p)
                scrollView.addSubview(button)
                maxHeight = button.frame.origin.y + button.frame.height + margin
                probeCount += 1
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        logFunctionName()
        for v in scrollView.subviews {
            v.removeFromSuperview()
        }
        probeCount = 0
    }
    
    func createButton(_ shLight: SHLight) -> UIButton {
        let width = scrollView.frame.width / 2 - 3 * margin
        let height = width * 6
        let x = CGFloat(probeCount % 2) * (margin + width) + margin
        let y = CGFloat(probeCount / 2) * (margin + height)
        let rect = CGRect(x: x, y: y, width: width, height: height)
        let button = UIButton(frame: rect)
        button.setImage(shLight.environmentImage, for: .normal)
        button.tag = probeCount
        button.addTarget(self, action: #selector(EnvMapSelectionViewController.buttonAction(_:)), for: UIControl.Event.primaryActionTriggered)
        return button
    }
    
    @IBAction func pressDone(_ sender: AnyObject) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func buttonAction(_ sender:UIButton!) {
        guard let image = sender.image(for: .normal) else {
            NSLog("Missing image for button: \(sender.tag)")
            return
        }
        shareImage(image)
    }
    
    func shareImage(_ image: UIImage) {
        guard let imageData = image.pngData() else {
            return
        }
        let activityItems : [AnyObject] = [imageData as AnyObject]
        let activity = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        // sourceView is needed on iPad or it'll crash
        activity.popoverPresentationController?.sourceView = self.view
        self.present(activity, animated: true, completion: nil)
    }
}
