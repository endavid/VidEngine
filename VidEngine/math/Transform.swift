//
//  Transform.swift
//  VidEngine
//
//  Created by David Gavilan on 8/13/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Foundation

struct Transform {
    var position = Vector3()
    var scale = Vector3(x: 1, y: 1, z: 1)
    var rotation = Quaternion()
}