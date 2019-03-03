//
//  SHBuffer.swift
//  VidFramework
//
//  Created by David Gavilan on 2019/02/16.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import MetalKit
import simd

class SHBuffer: SHStorage {
    let numBands    : UInt
    let numCoeffs   : UInt
    let numSamples  : UInt
    let sqrtSamples : UInt
    var normalBuffer      : MTLBuffer!
    var radianceBuffer    : MTLBuffer!
    /// Irradiance matrices will need to be copied to a MTLBuffer for rendering
    var irradiances       : [float4x4]
    var sphericals        : [Spherical]
    var coeffsPerSample   : [[Double]]
    var coeffs            : [Vec3]

    
    var normals: UnsafeMutablePointer<Vec3> {
        get {
            return normalBuffer.contents().assumingMemoryBound(to: Vec3.self)
        }
    }
    var radiances: UnsafeMutablePointer<Vec3> {
        get {
            return radianceBuffer.contents().assumingMemoryBound(to: Vec3.self)
        }
    }
    
    init(device: MTLDevice, numBands: UInt = 3, sqrtSamples: UInt = 100) {
        self.numBands = numBands
        self.numSamples = sqrtSamples * sqrtSamples
        self.sqrtSamples = sqrtSamples
        numCoeffs = numBands * numBands
        irradiances = Array(repeating: float4x4(), count: 3)
        let n = Int(self.numSamples)
        let coefficients = [Double](repeating: 0, count: Int(numCoeffs))
        coeffsPerSample = [[Double]](repeating: coefficients, count: n)
        sphericals = [Spherical](repeating: Spherical(), count: n)
        normalBuffer = Renderer.createBuffer(from: Vec3.zero, device: device, numCopies: n)
        radianceBuffer = Renderer.createBuffer(from: Vec3.zero, device: device, numCopies: n)
        coeffs = [Vec3](repeating: .zero, count: Int(numCoeffs))
    }
    
    func getSample(i: Int) -> SHSample {
        return SHSample(sph: sphericals[i], vec: normals[i], coeff: coeffsPerSample[i])
    }
    
    func getCoefficient(i: Int) -> Vec3 {
        return coeffs[i]
    }

    func getIrradiance(i: Int) -> float4x4 {
        return irradiances[i]
    }

    func setSample(i: Int, sph: Spherical) {
        sphericals[i] = sph
    }
    
    func setSample(i: Int, vec: Vec3) {
        normals[i] = vec
    }
    
    func setSample(i: Int, ci: Int, _ value: Double) {
        coeffsPerSample[i][ci] = value
    }
    
    func setCoefficient(i: Int, _ vec: Vec3) {
        coeffs[i] = vec
    }
    
    func setIrradiance(i: Int, _ m: float4x4) {
        irradiances[i] = m
    }
}
