//
//  UIViewExtension.swift
//  SampleAR
//
//  Created by David Gavilan on 02/12/2021.
//  Copyright © 2021 David Gavilan. All rights reserved.
//

// https://spin.atomicobject.com/2017/07/18/swift-interface-builder/

import UIKit

@IBDesignable
class DesignableView: UIView {
}

extension UIView {
    
    @IBInspectable
    var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }
    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    @IBInspectable
    var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.borderColor = color.cgColor
            } else {
                layer.borderColor = nil
            }
        }
    }
}
