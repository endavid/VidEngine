//
//  Util.swift
//  VidFramework
//
//  Created by David Gavilan on 02/12/2021.
//  Copyright © 2021 David Gavilan. All rights reserved.
//

import Foundation

// https://docs.swift.org/swift-book/ReferenceManual/Expressions.html
// https://stackoverflow.com/a/24402688/1765629
public func logFunctionName(file: String = #file, fn: String = #function) {
    #if DEBUG
    let base = (file as NSString).lastPathComponent
    NSLog("\(base): \(fn)")
    #endif
}

public func logDebug(_ text: String) {
    #if DEBUG
    NSLog(text)
    #endif
}
