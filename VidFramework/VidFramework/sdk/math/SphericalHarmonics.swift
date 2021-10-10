//
//  SphericalHarmonics.swift
//  VidFramework
//
//  Created by David Gavilan on 2019/02/15.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import simd

/** SphericalHarmonics Samples */
public struct SHSample {
    public var sph:    Spherical
    public var vec:    Vec3
    public var coeff:  [Double]
    public init(sph: Spherical, vec: Vec3, coeff: [Double]) {
        self.sph = sph
        self.vec = vec
        self.coeff = coeff
    }
}

public protocol SHStorage {
    var numBands    : UInt { get }
    var numCoeffs   : UInt { get }
    var numSamples  : UInt { get }
    var sqrtSamples : UInt { get }
    func getSample(i: Int) -> SHSample
    func getCoefficient(i: Int) -> Vec3
    func getIrradiance(i: Int) -> float4x4
    func setSample(i: Int, sph: Spherical)
    func setSample(i: Int, vec: Vec3)
    func setSample(i: Int, ci: Int, _ value: Double)
    func setCoefficient(i: Int, _ vec: Vec3)
    func setIrradiance(i: Int, _ m: float4x4)
}

public class SphericalHarmonicsArrays: SHStorage {
    public let numBands    : UInt
    public let numCoeffs   : UInt
    public let numSamples  : UInt
    public let sqrtSamples : UInt
    var samples     : [SHSample]
    var coeffs      : [Vec3]
    /// Irradiance matrices
    var irradiances : [float4x4]

    public init(numBands: UInt = 3, sqrtSamples: UInt = 100) {
        self.numBands = numBands
        self.numSamples = sqrtSamples * sqrtSamples
        self.sqrtSamples = sqrtSamples
        numCoeffs = numBands * numBands
        irradiances = Array(repeating: float4x4(), count: 3)
        // init samples with 0-arrays, so they can be indexed in setupSphericalSamples
        let coefficients = [Double](repeating: 0, count: Int(numCoeffs))
        let emptySample = SHSample(sph: Spherical(), vec: .zero, coeff: coefficients)
        samples = [SHSample](repeating: emptySample, count: Int(self.numSamples))
        coeffs = [Vec3](repeating: .zero, count: Int(numCoeffs))
    }
    
    public func getSample(i: Int) -> SHSample {
        return samples[i]
    }
    
    public func getCoefficient(i: Int) -> Vec3 {
        return coeffs[i]
    }
    
    public func getIrradiance(i: Int) -> float4x4 {
        return irradiances[i]
    }

    public func setSample(i: Int, sph: Spherical) {
        samples[i].sph = sph
    }
    
    public func setSample(i: Int, vec: Vec3) {
        samples[i].vec = vec
    }
    
    public func setSample(i: Int, ci: Int, _ value: Double) {
        samples[i].coeff[ci] = value
    }
    
    public func setCoefficient(i: Int, _ vec: Vec3) {
        coeffs[i] = vec
    }
    
    public func setIrradiance(i: Int, _ m: float4x4) {
        irradiances[i] = m
    }
}

public class SphericalHarmonics {
    var storage: SHStorage
    let oneOverN: Double
    var initStep: UInt
    
    public var isInit: Bool {
        get {
            return initStep == storage.numSamples
        }
    }
    
    public init(_ storage: SHStorage) {
        self.storage = storage
        oneOverN = 1.0 / Double(storage.sqrtSamples)
        initStep = 0
    }
    
    /// Initializes the SHSamples
    /// fill an N*N*2 array with uniformly distributed
    /// samples across the sphere using jittered stratification
    public func initNextSphericalSample() {
        if isInit {
            return
        }
        let i = Int(initStep)
        let a = initStep / storage.sqrtSamples
        let b = initStep % storage.sqrtSamples
        // generate unbiased distribution of spherical coords
        // & do not reuse results, each sample must be random
        let x = (Double(a)+Double(Randf())) * oneOverN
        let y = (Double(b)+Double(Randf())) * oneOverN
        let θ = 2.0 * acos(sqrt(1.0 - x))
        let φ = 2.0 * π * y
        let sph = Spherical(r: 1.0, θ: Float(θ), φ: Float(φ))
        storage.setSample(i: i, sph: sph)
        // convert spherical coords to unit vector
        storage.setSample(i: i, vec: Vec3(sph.toCartesian()))
        // precompute all SH coefficients for this sample
        for l in 0..<Int(storage.numBands) {
            for m in -l...l {
                let ci = l * (l+1) + m // coefficient index
                let sh = SH(l: l,m: m,θ: θ,φ: φ)
                // accessing the array here seems to be a bit slow...
                storage.setSample(i: i, ci: ci, sh)
            }
        }
        initStep += 1
    }
    
    /// evaluate an Associated Legendre Polynomial P(l,m,x) at x
    func P(l: Int, m: Int, x: Double) -> Double {
        var pmm : Double = 1.0
        if (m>0) {
            let somx2 = sqrt((1.0-x)*(1.0+x))
            var fact = 1.0
            for _ in 1...m {
                pmm *= (-fact) * somx2;
                fact += 2.0;
            }
        }
        if (l==m) {
            return pmm
        }
        var pmmp1 = x * (2.0*Double(m)+1.0) * pmm
        if (l==m+1) {
            return pmmp1
        }
        var pll : Double = 0.0
        var ll = m+2
        while ll<=l {
            pll = ( (2.0*Double(ll)-1.0)*x*pmmp1-(Double(ll+m)-1.0)*pmm ) / Double(ll-m)
            pmm = pmmp1
            pmmp1 = pll
            ll+=1
        }
        return pll
    }
    
    /// renormalization constant for SH function
    func K(l: Int, m: Int) -> Double {
        let temp = ((2.0*Double(l)+1.0)*Factorial(l-m)) / (4.0*π*Factorial(l+m))
        return sqrt(temp)
    }
    
    /**
     A point sample of a Spherical Harmonic basis function
     - parameters:
       - l: is the band, range [0..N]
       - m: in the range [-l..l]
       - θ: in the range [0..Pi]
       - φ: in the range [0..2*Pi]
    */
    func SH(l: Int, m: Int, θ: Double, φ: Double) -> Double {
        let sqrt2 : Double = sqrt(2.0)
        if (m==0) {
            return K(l: l,m: 0) * P(l: l,m: m,x: cos(θ))
        }
        else if (m>0) {
            return sqrt2 * K(l: l, m: m) * cos(Double(m)*φ) * P(l: l,m: m,x: cos(θ))
        }
        else {
            return sqrt2 * K(l: l, m: -m) * sin(Double(-m)*φ) * P(l: l,m: -m,x: cos(θ))
        }
    }
    
    /**
     Projects a polar function and computes the SH Coeffs
     - parameters:
       - fn: the Polar Function. If the polar function is an image, pass a function that retrieves (R,G,B) values from it given a spherical coordinate.
    */
    public func projectPolarFn(_ fn: (Float, Float) -> Vec3) {
        // for each sample
        for i : Int in 0..<Int(storage.numSamples) {
            let sample = storage.getSample(i: i)
            let θ = sample.sph.θ
            let φ = sample.sph.φ
            updateCoefficients(sampleIndex: i, fn(θ,φ))
        }
        normalizeCoefficients()
        // compute matrices for later
        computeIrradianceApproximationMatrices()
    }
    
    func updateCoefficients(sampleIndex i: Int, _ v: Vec3) {
        let coeff = storage.getSample(i: i).coeff
        for n : Int in 0..<Int(storage.numCoeffs) {
            let c = storage.getCoefficient(i: n)
            storage.setCoefficient(i: n, c + v * Float(coeff[n]))
        }
    }
    
    func normalizeCoefficients() {
        // divide the result by weight and number of samples
        let weight: Float = 4.0 * .pi
        let factor = weight / Float(storage.numSamples)
        for i : Int in 0..<Int(storage.numCoeffs) {
            let c = storage.getCoefficient(i: i)
            storage.setCoefficient(i: i, factor * c)
        }
    }
    
    
    /**
     * Reconstruct the approximated function for the given input direction,
     * given in spherical/polar coordinates
     */
    public func reconstruct(θ: Double, φ: Double) -> simd_float3
    {
        var o = simd_float3(0, 0, 0)
        for l in 0..<Int(storage.numBands) {
            for m in -l...l {
                let ci = l * (l+1) + m // coefficient index
                let sh = Float(SH(l: l,m: m,θ: θ,φ: φ))
                let c = storage.getCoefficient(i: ci)
                o += sh * simd_float3(c)
            }
        }
        return o
    }
    
    /**
     * Reconstruct the approximated function for the given input direction
     */
    public func reconstruct(direction: simd_float3) -> simd_float3
    {
        let sp = Spherical(v: direction)
        return reconstruct(θ: Double(sp.θ), φ: Double(sp.φ))
    }
    
    
    /**
     * Computes matrix M used to approximate irradiance E(n).
     * For normal direction n, E(n) = n^ * M * n
     * @see "An efficient representation for Irradiance Environment Maps"
     */
    func computeIrradianceApproximationMatrices() {
        if storage.numBands < 3 {
            NSLog("Not enough coefficients!")
            return
        }
        let pi = Float.pi
        let a0 = pi * 1.0
        let a1 = pi * 2.0/3.0
        let a2 = pi * 1.0/4.0
        let k0 = (1.0/4.0) * sqrtf(15.0/pi) * a2
        let k1 = (1.0/4.0) * sqrtf(3.0/pi) * a1
        let k2 = (1.0/2.0) * sqrtf(1.0/pi) * a0
        let k3 = (1.0/4.0) * sqrtf(5.0/pi) * a2
        
        // coeff: L00, L1-1, L10, L11, L2-2, L2-1, L20, L21, L22
        // for every color channel
        for i in 0...2 {
            var m = float4x4()
            m[0,0] = k0 * storage.getCoefficient(i: 8)[i]
            m[1,0] = k0 * storage.getCoefficient(i: 4)[i]
            m[2,0] = k0 * storage.getCoefficient(i: 7)[i]
            m[3,0] = k1 * storage.getCoefficient(i: 3)[i]
            m[0,1] = k0 * storage.getCoefficient(i: 4)[i]
            m[1,1] = -k0 * storage.getCoefficient(i: 8)[i]
            m[2,1] = k0 * storage.getCoefficient(i: 5)[i]
            m[3,1] = k1 * storage.getCoefficient(i: 1)[i]
            m[0,2] = k0 * storage.getCoefficient(i: 7)[i]
            m[1,2] = k0 * storage.getCoefficient(i: 5)[i]
            m[2,2] = 3.0 * k3 * storage.getCoefficient(i: 6)[i]
            m[3,2] = k1 * storage.getCoefficient(i: 2)[i]
            m[0,3] = k1 * storage.getCoefficient(i: 3)[i]
            m[1,3] = k1 * storage.getCoefficient(i: 1)[i]
            m[2,3] = k1 * storage.getCoefficient(i: 2)[i]
            m[3,3] = k2 * storage.getCoefficient(i: 0)[i] - k3 * storage.getCoefficient(i: 6)[i]
            storage.setIrradiance(i: i, m)
        }
    } // computeIrradianceApproximationMatrices
    
    /**
     * Computes the approximate irradiance for the given normal direction
     *  E(n) = n^ * M * n
     */
    public func getIrradianceApproximation(normal: simd_float3) -> simd_float3 {
        var v = simd_float3()
        // In the original paper, (x,y,z) = (sinθcosφ, sinθsinφ, cosθ),
        // but in our Spherical class the vertical axis cosθ is Y
        let n = simd_float4(x: -normal.z, y: -normal.x, z: normal.y, w: 1)
        // for every color channel
        v.x = dot(n, storage.getIrradiance(i: 0) * n)
        v.y = dot(n, storage.getIrradiance(i: 1) * n)
        v.z = dot(n, storage.getIrradiance(i: 2) * n)
        return v
    }
}
