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
    var samplesBuffer     : MTLBuffer!
    var coeffsBuffer      : MTLBuffer!
    /// Irradiance matrices
    var irradiancesBuffer : MTLBuffer!

    var samples: UnsafeMutablePointer<SHSample> {
        get {
            return samplesBuffer.contents().assumingMemoryBound(to: SHSample.self)
        }
    }
    var coeffs: UnsafeMutablePointer<Vec3> {
        get {
            return coeffsBuffer.contents().assumingMemoryBound(to: Vec3.self)
        }
    }
    var irradiances: UnsafeMutablePointer<float4x4> {
        get {
            return irradiancesBuffer.contents().assumingMemoryBound(to: float4x4.self)
        }
    }
    
    init(device: MTLDevice, numBands: UInt = 3, sqrtSamples: UInt = 100) {
        self.numBands = numBands
        self.numSamples = sqrtSamples * sqrtSamples
        self.sqrtSamples = sqrtSamples
        numCoeffs = numBands * numBands
        let emptyMatrix = float4x4()
        irradiancesBuffer = Renderer.createBuffer(from: emptyMatrix, device: device, numCopies: 3)
        let coefficients = [Double](repeating: 0, count: Int(numCoeffs))
        let emptySample = SHSample(sph: Spherical(), vec: .zero, coeff: coefficients)
        samplesBuffer = Renderer.createBuffer(from: emptySample, device: device, numCopies: Int(self.numSamples))
        coeffsBuffer = Renderer.createBuffer(from: Vec3.zero, device: device, numCopies: Int(numCoeffs))
    }
    
    func getSample(i: Int) -> SHSample {
        return samples[i]
    }
    
    func getCoefficient(i: Int) -> Vec3 {
        return coeffs[i]
    }

    func getIrradiance(i: Int) -> float4x4 {
        return irradiances[i]
    }

    func setSample(i: Int, sph: Spherical) {
        samples[i].sph = sph
    }
    
    func setSample(i: Int, vec: Vec3) {
        samples[i].vec = vec
    }
    
    func setSample(i: Int, ci: Int, _ value: Double) {
        samples[i].coeff[ci] = value
    }
    
    func setCoefficient(i: Int, _ vec: Vec3) {
        coeffs[i] = vec
    }
    
    func setIrradiance(i: Int, _ m: float4x4) {
        irradiances[i] = m
    }
}
