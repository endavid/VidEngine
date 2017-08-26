//
//  Math.swift
//
//  Created by David Gavilan on 3/19/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Foundation
import CoreGraphics

extension Float {
    static let pi : Float = 3.1415926535897932384626433832795
    static let tau : Float = .pi * 2
    static let halfPi : Float = .pi / 2
    static let piInv : Float = 1.0 / .pi
}

let NORM_SQR_ERROR_TOLERANCE : Float = 0.001

extension Double {
    static let pi : Double = Double(Float.pi)
}


/// Converts angle in degrees to radians
func DegToRad(_ angle: Float) -> Float {
    return angle * (Float.pi/180.0)
}

/// Ceil for ints
func CeilDiv(_ a: Int, b: Int) -> Int {
    return (a + b - 1) / b
}
func IsClose(_ a: Float, _ b: Float, epsilon: Float = 0.0001) -> Bool {
    return ( fabsf( a - b ) < epsilon )
}

extension ClosedRange {
    public func clamp(_ value: Bound) -> Bound {
        return min(max(value, lowerBound), upperBound)
    }
}

extension CGSize {
    @inline(__always)
    static func *(lhs: CGSize, rhs: CGFloat) -> CGSize {
        return CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
}

/// Random Int. Preferred to rand() % upperBound
func Rand(_ upperBound: UInt32) -> UInt32 {
    return arc4random_uniform(upperBound)
}
/// Random Float between 0 and 1
func Randf() -> Float {
    return Float(Rand(10000)) * 0.0001
    // or use drand48? needs a seed srand48
}
/// Random sign
func RandSign() -> Float {
    return (Rand(2) == 0 ? -1.0 : 1.0)
}
/// Random event with given probabily
func RandEvent(_ probality: Float) -> Bool {
    let r = Float(Rand(10000))
    return r < 10000.0 * probality
}
extension Array {
    func shuffled() -> [Element] {
        var list = self
        for i in 0..<(list.count - 1) {
            // I need a seeded rand() to make it deterministic
            let upperBound = UInt32(list.count - i)
            let j = Int(UInt32(arc4random()) % upperBound) + i
            //let j = Int(arc4random_uniform(upperBound)) + i
            guard i != j else { continue }
            swap(&list[i], &list[j])
        }
        return list
    }
}
