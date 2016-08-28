//: Playground - noun: a place where people can play

import simd

let nums : [Float] = [-1, 0, 1, 2, 3, 4, 5, 6, 7, 8]
let numsVoid = UnsafeMutablePointer<Void>(nums)
let numsOffset = UnsafeMutablePointer<Float>(numsVoid + sizeof(Float) * 3)
numsOffset[0]

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

sizeof(TexturedVertex)
sizeof(float3)
sizeof(Vec3)

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

var int3Array = [int3](count: 10, repeatedValue: int3(0,0,0))
var arrayCopy = int3Array
int3Array[0] = int3(1, 2, 3)
int3Array[0]
arrayCopy[0] // unaffected because int3 is not a ref value



