//
//  Errors.swift
//  VidEngine
//
//  Created by David Gavilan on 2017/05/29.
//  Copyright © 2017 David Gavilan. All rights reserved.
//

import Foundation

public enum SerializationError: Error {
    case missing(String)
    case invalid(String, Any)
}

public enum MathError: Error {
    case unsupported(String)
}

public enum FileError: Error {
    case missing(String)
    case corrupt(String)
}
