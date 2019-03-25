//
//  Math.swift
//
//  Created by David Gavilan on 3/19/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Foundation
import UIKit

let PI_2   : Float  = 0.5 * .pi
let PI2    : Float  = 2.0 * .pi
let PI_INV : Float  = 1.0 / .pi
let NORM_SQR_ERROR_TOLERANCE : Float = 0.001
let GENEROUS_EPSILON: Float = 0.0001
let π       : Double = .pi

/// Converts angle in degrees to radians
public func DegToRad(_ angle: Float) -> Float {
    return angle * (.pi/180.0)
}
/// Gets the sign of a number
func Sign(_ n: Float) -> Float {
    return (n>=0) ?1:-1
}
/// Max
func Max(_ a: CGFloat, b: CGFloat) -> CGFloat {
    return (a>=b) ?a:b
}
func Max(_ a: Float, b: Float) -> Float {
    return (a>=b) ?a:b
}
func Max(_ a: Int, b: Int) -> Int {
    return (a>=b) ?a:b
}
/// Min
func Min(_ a: CGFloat, b: CGFloat) -> CGFloat {
    return (a<=b) ?a:b
}
func Min(_ a: Float, b: Float) -> Float {
    return (a<=b) ?a:b
}
func Min(_ a: Int, b: Int) -> Int {
    return (a<=b) ?a:b
}
/// Ceil for ints
func CeilDiv(_ a: Int, b: Int) -> Int {
    return (a + b - 1) / b
}
public func IsClose(_ a: Float, _ b: Float, epsilon: Float = 0.0001) -> Bool {
    return ( fabsf( a - b ) < epsilon )
}
public func IsClose(_ a: CGFloat, _ b: CGFloat, epsilon: Float = 0.0001) -> Bool {
    return ( fabsf( Float(a - b) ) < epsilon )
}

/// Clamp
public func Clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
    return (value<min) ?min:(value>max) ?max:value
}
public func Clamp(_ value: Float, min: Float, max: Float) -> Float {
    return (value<min) ?min:(value>max) ?max:value
}
public func Clamp(_ value: Int, min: Int, max: Int) -> Int {
    return (value<min) ?min:(value>max) ?max:value
}
/// Random Int. Preferred to rand() % upperBound
public func Rand(_ upperBound: UInt32) -> UInt32 {
    return arc4random_uniform(upperBound)
}
public func Rand(_ upperBound: Int) -> Int {
    return Int(Rand(UInt32(upperBound)))
}
/// Random Float between 0 and 1
public func Randf() -> Float {
    return Float(Rand(10000)) * 0.0001
    // or use drand48? needs a seed srand48
}
/// Random sign
public func RandSign() -> Float {
    return (Rand(2) == 0 ? -1.0 : 1.0)
}
/// Random event with given probabily
public func RandEvent(_ probality: Float) -> Bool {
    let r = Float(Rand(10000))
    return r < 10000.0 * probality
}

// Factorial of a number with a cache
public func Factorial(_ n: Int) -> Double { // 64-bit ints aren't enough for big factorials
    struct CacheData {
        static let maxCount = 33
        static var isFactorialCached = false
        static var factorialCache : [Double] = [Double](repeating: 1, count: maxCount)
    }
    
    if (n < 2) {
        return 1
    }
    if (!CacheData.isFactorialCached) {
        // init cache
        var r : Double = 1
        for c in 0..<CacheData.maxCount {
            r *= Double(c+2)
            CacheData.factorialCache[c] = r
        }
        CacheData.isFactorialCached = true
    }
    if (n - 2 < CacheData.maxCount) {
        return CacheData.factorialCache[n-2]
    }
    var r = CacheData.factorialCache[CacheData.maxCount-1]
    for i in (CacheData.maxCount+2)...n {
        r *= Double(i)
    }
    return r
}

public extension Array {
    func shuffled() -> [Element] {
        var list = self
        for i in 0..<(list.count - 1) {
            // I need a seeded rand() to make it deterministic
            let upperBound = UInt32(list.count - i)
            let j = Int(UInt32(arc4random()) % upperBound) + i
            //let j = Int(arc4random_uniform(upperBound)) + i
            guard i != j else { continue }
            list.swapAt(i, j)
        }
        return list
    }
    func randomElement() -> Element {
        let i = Rand(self.count)
        return self[i]
    }
    // https://stackoverflow.com/a/38156873/1765629
    func chunked(by chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
}

public extension Float {
    /// Rounds to decimal places value
    func rounded(toPlaces places:Int) -> Float {
        let divisor = powf(10.0, Float(places))
        return (self * divisor).rounded() / divisor
    }
}
