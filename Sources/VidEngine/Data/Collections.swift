//
//  Collections.swift
//  VidEngine
//
//  Created by David Gavilan on 9/4/16.
//

import Foundation

// http://stackoverflow.com/a/33674192/1765629
extension Collection where Index: Strideable {
    /// Finds such index N that predicate is true for all elements up to
    /// but not including the index N, and is false for all elements
    /// starting with index N.
    /// Behavior is undefined if there is no such N.
    func binarySearch(_ predicate: (Iterator.Element) -> Bool) -> Index {
        var low = startIndex
        var high = endIndex
        while low != high {
            let mid = self.index(low, offsetBy: self.distance(from: low, to: high) / 2)
            if predicate(self[mid]) {
                low = self.index(mid, offsetBy: 1)
            } else {
                high = mid
            }
        }
        return low
    }
}
