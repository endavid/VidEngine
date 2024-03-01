//
//  Errors.swift
//  VidEngine
//
//  Created by David Gavilan on 2017/05/29.
//

import Foundation

public enum SerializationError: Error {
    case missing(String)
    case invalid(String, Any)
}

public enum MathError: Error {
    case unsupported(String)
}

public enum SphericalHarmonicsError: Error {
    case notEnoughCoefficients
}

public enum FileError: Error {
    case missing(String)
    case corrupt(String)
}
