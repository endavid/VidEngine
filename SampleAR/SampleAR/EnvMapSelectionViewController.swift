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
    
    @IBOutlet weak var contentView: UIView!
    
    var probeCount = 0
    
    override func viewWillLayoutSubviews() {
        logFunctionName()
    }
    override func viewDidLayoutSubviews() {
        logFunctionName()
        if let vid = self.presentingViewController as? VidController {
            let probes = vid.scene.lights.compactMap { $0 as? SHLight }
            for p in probes {
                let button = createButton(p)
                contentView.addSubview(button)
                probeCount += 1
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        logFunctionName()
        for v in contentView.subviews {
            v.removeFromSuperview()
        }
        probeCount = 0
    }
    
    func createButton(_ shLight: SHLight) -> UIButton {
        let margin: CGFloat = 10
        let width = contentView.frame.width - 2 * margin
        let height = width / 3
        let y = CGFloat(probeCount) * (margin + height)
        let rect = CGRect(x: margin, y: y, width: width, height: height)
        let button = UIButton(frame: rect)
        button.setImage(shLight.environmentImage, for: .normal)
        return button
    }
    
    @IBAction func pressDone(_ sender: AnyObject) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
