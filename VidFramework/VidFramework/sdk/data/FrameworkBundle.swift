//
//  FrameworkBundle.swift
//  VidFramework
//
//  Created by David Gavilan on 2018/02/18.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import Foundation

public enum FrameworkError: Error {
    case missing(String)
}

public class FrameworkBundle {
    static let mainBundleId = "com.endavid.VidFramework"
    
    public static func mainBundle() throws -> Bundle {
        if let bundle = Bundle.init(identifier: mainBundleId) {
            return bundle
        }
        throw FrameworkError.missing(mainBundleId)
    }
}

