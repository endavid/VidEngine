//
//  ViewController.swift
//  SampleCornellBox
//
//  Created by David Gavilan on 2018/02/19.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import UIKit
import VidFramework

class ViewController: VidController {
    private let mainScenePath = "CornellBox"
    private var scene: Scene?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        scene?.dequeueAll()
    }

    private func setupScene() {
        guard let path = Bundle.main.path(forResource: mainScenePath, ofType: "mdla") else {
            NSLog("Missing resource: \(mainScenePath)")
            return
        }
        NSLog(path)
        let parser = MdlParser(path: path)
        scene = parser.parse()
        scene?.queueAll()
    }

}

