//
//  Quaternion.swift
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Foundation

struct Quaternion : CustomStringConvertible {
    var w : Float	= 1 ///< real part (scalar)
    var v = Vector3()	///< imaginary part (vector)
    var description : String {
        return "q(w: \(w), v: (\(v.x), \(v.y), \(v.z)))"
    }
    func toString() -> String {
        return description
    }
   
}