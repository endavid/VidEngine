//
//  SettingsViewController.swift
//  SampleAR
//
//  Created by David Gavilan on 10/12/2021.
//  Copyright © 2021 David Gavilan. All rights reserved.
//

import UIKit
import VidFramework

class SettingsViewController: UIViewController {
 
    @IBOutlet weak var switchDebug: UISwitch!
    @IBOutlet weak var switchGlobalLighting: UISwitch!
    @IBOutlet weak var sizeLocalCaptureSlider: UISlider!
    
    override func viewWillAppear(_ animated: Bool) {
        if let vc = self.presentingViewController as? ViewController {
            switchDebug.isOn = vc.isDebug
            switchGlobalLighting.isOn = vc.isGlobalLight
            sizeLocalCaptureSlider.value = vc.localSHLightSize
        }
    }
    
    @IBAction func pressDone(_ sender: AnyObject) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func showDebugElements(_ sender: UISwitch!) {
        if let vc = self.presentingViewController as? ViewController {
            vc.setDebugging(sender.isOn)
        }
    }
    
    @IBAction func useGlobalLighting(_ sender: UISwitch!) {
        if let vc = self.presentingViewController as? ViewController {
            vc.isGlobalLight = sender.isOn
        }
    }
    
    @IBAction func updateSizeLocalCapture(_ sender: UISlider!) {
        if let vc = self.presentingViewController as? ViewController {
            vc.localSHLightSize = sender.value
        }
    }
    
}
