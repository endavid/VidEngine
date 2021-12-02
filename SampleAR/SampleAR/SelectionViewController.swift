//
//  SelectionViewController.swift
//  SampleAR
//
//  Created by David Gavilan on 2019/03/25.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import UIKit

enum ModelOption: String {
    case sphere = "sphere"
    case cube = "cube"
    case houseSantorini = "houseSantorini"
}

class SelectionViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet weak var pickerView: UIPickerView!
    
    let modelList = [ModelOption.sphere, ModelOption.cube, ModelOption.houseSantorini]
    var selectedItem = ModelOption.sphere
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerView.delegate = self
        pickerView.dataSource = self
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func pressDone(_ sender: AnyObject) {
        if let vc = presentingViewController as? ViewController {
            vc.model = selectedItem
        }
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - PickerView
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return modelList.count
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedItem = modelList[row]
    }
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        if #available(iOS 13.0, *) {
            return NSAttributedString(string: modelList[row].rawValue, attributes: [NSAttributedString.Key.foregroundColor: UIColor.label])
        } else {
            // Fallback on earlier versions
            return NSAttributedString(string: modelList[row].rawValue, attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
        }
    }
}
