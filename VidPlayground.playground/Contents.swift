//: Playground - noun: a place where people can play

import simd
import CoreGraphics

infix operator >>> : BitwiseShiftPrecedence

func >>> (lhs: Int64, rhs: Int64) -> Int64 {
    return Int64(bitPattern: UInt64(bitPattern: lhs) >> UInt64(rhs))
}
Int64(-7) >> 16
Int64(-7) >>> 16
let a : Int64 = 203227649148896
a >>> 16


let nums : [Float] = [-1, 0, 1, 2, 3, 4, 5, 6, 7, 8]
let numsVoid = UnsafeMutableRawPointer(mutating: nums)
let numsOffset = numsVoid.assumingMemoryBound(to: Float.self)
numsOffset[2]

struct Vec3 {
    let x : Float
    let y : Float
    let z : Float
}

struct Vec2 {
    let x : Float
    let y : Float
}

struct TexturedVertex {
    let position : Vec3
    let normal : Vec3
    let uv : Vec2
}

MemoryLayout<TexturedVertex>.size
MemoryLayout<float3>.size
MemoryLayout<Vec3>.size

struct Pan {
    let rating : Int
}

class Queso {
    let rating : Int
    init(rating: Int) {
        self.rating = rating
    }
}

var q1 = Queso(rating: 0)
var q2 = Queso(rating: 0)
var q3 = q1 // same reference
var q4 = Queso(rating: 1)
//q1 == q2 // error, == not defined
q1 === q2 // false
q3 === q1 // true
var p1 = Pan(rating: 0)
var p2 = Pan(rating: 0)
//p1 == p2 // error, == not defined
//p1 === p2 // error, can't be applied to structs
let quesos = [q1, q2]
// quesos.contains(q1) // error, can't convert q1 to predicate
quesos.contains { $0 === q1 } // true
quesos.contains { $0 === q3 } // true
quesos.contains { $0 === q4 } // false

func ==(lhs: Queso, rhs: Queso) -> Bool {
    return lhs.rating == rhs.rating
}
q1 == q2 // true
q1 == q4 // false
//quesos.contains(q1) // true if Queso : Equatable

func ==(lhs: Pan, rhs: Pan) -> Bool {
    return lhs.rating == rhs.rating
}
p1 == p2 // true

var int3Array = [int3](repeating: int3(0,0,0), count: 10)
var arrayCopy = int3Array
int3Array[0] = int3(1, 2, 3)
int3Array[0]
arrayCopy[0] // unaffected because int3 is not a ref value

let str : String = "mtrl \"la mare\" hello"
let i0 = str.characters.index(of: "\"")
let split = str.split(separator: "\"")
let name : String = String(split[1])

let d65 = float3(0.950, 1, 1.089)
let m = float3x3([float3(0.5151, 0.2412, -0.0011),
                  float3(0.2920, 0.6922, 0.0419),
                  float3(0.1571, 0.0666, 0.7841)])
let s = m.inverse * d65

print(s)

public struct CiexyY {
    public let xyY: float3
    public var x: Float {
        get {
            return xyY.x
        }
    }
    public var y: Float {
        get {
            return xyY.y
        }
    }
    public var Y: Float {
        get {
            return xyY.z
        }
    }
    public var xyz: float3 {
        get {
            return float3(x*Y/y, Y, (1-x-y)*Y/y)
        }
    }
    public init(x: Float, y: Float, Y: Float = 1) {
        xyY = float3(x, y, Y)
    }
}

let rr = CiexyY(x: 0.680, y: 0.320)
let gg = CiexyY(x: 0.265, y: 0.690)
let bb = CiexyY(x: 0.150, y: 0.060)
print(rr.xyz)
print(gg.xyz)
print(bb.xyz)

let linearSpace = CGColorSpace(name: CGColorSpace.linearSRGB)!
let gammaSpace = CGColorSpace(name: CGColorSpace.sRGB)!
let v0 = float3(0.0031308, 0.02, 0.04)
let components: [CGFloat] = [CGFloat(v0.x), CGFloat(v0.y), CGFloat(v0.z)]
let c = CGColor(colorSpace: linearSpace, components: components)!
let cγ = c.converted(to: gammaSpace, intent: .defaultIntent, options: nil)!
let v = float3(Float(cγ.components![0]), Float(cγ.components![1]), Float(cγ.components![2]))
v.x
v.y
v.z

let gx = log(v0.x * 1.055) / log(v.x + 0.055)
let gy = log(v0.y * 1.055) / log(v.y + 0.055)
let gz = log(v0.z * 1.055) / log(v.z + 0.055)
(v.z - v.x) / v.y

powf(v0.x*1.352, 3.32) + 0.53
powf(v0.y*1.352, 3.32) + 0.53
powf(v0.z*1.352, 3.32) + 0.53

powf(v0.x*33871620, 0.078) - 2.94
powf(v0.y*33871620, 0.078) - 2.94
powf(v0.z*33871620, 0.078) - 2.94
