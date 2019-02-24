//
//  SHLight.swift
//  VidFramework
//
//  Created by David Gavilan on 2019/02/19.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import MetalKit
import ARKit

public class SHLight: LightSource {
    enum Phase {
        case
        initSamples,
        readCubemap,
        computeSH,
        readyToRender
    }
    let shBuffer: SHBuffer
    let sh: SphericalHarmonics
    public var transform: Transform
    internal var vertexBuffer: MTLBuffer!
    internal var indexBuffer: MTLBuffer!
    fileprivate var _phase: Phase
    fileprivate var _sampleIndex: Int
    fileprivate var _anchor: ARAnchor?
    
    var areSamplesReady: Bool {
        get {
            return sh.isInit
        }
    }
    var phase: Phase {
        get {
            return _phase
        }
    }
    
    override public func queue() {
        // queue the deferred shading
        super.queue()
        // and the AR plugin
        if let plugin: ARPlugin? = Renderer.shared?.getPlugin(),
            let p = plugin {
            p.queue(self)
        }
    }
    
    override public func dequeue() {
        super.dequeue()
        if let plugin: ARPlugin? = Renderer.shared?.getPlugin(),
            let p = plugin {
            p.dequeue(self)
        }
    }
    
    public init(position: float3, extent: float3, session: ARSession) {
        if #available(iOS 12.0, *) {
            let probeAnchor = AREnvironmentProbeAnchor(name: "sceneProbe", transform: Transform(position: position).toMatrix4(), extent: extent)
            session.add(anchor: probeAnchor)
            _anchor = probeAnchor
        } else {
            NSLog("Environment Probe not available <iOS12.0")
        }
        let transform = Transform(position: position, scale: extent)
        self.transform = transform
        shBuffer = SHBuffer(device: Renderer.shared.device, numBands: 3, sqrtSamples: 100)
        sh = SphericalHarmonics(shBuffer)
        vertexBuffer = CubePrimitive.createCubeVertexBuffer()
        indexBuffer = CubePrimitive.createCubeIndexBuffer()
        _phase = .initSamples
        _sampleIndex = 0
    }
    
    func initOneRowOfSamples() {
        var i = 0
        while !sh.isInit && i < shBuffer.sqrtSamples {
            sh.initNextSphericalSample()
            i += 1
        }
    }
    
    func updateCoefficientsForOneRowOfSamples() {
        for i in 0..<Int(shBuffer.sqrtSamples) {
            let si = i + _sampleIndex
            let radiance = shBuffer.radiances[si]
            sh.updateCoefficients(sampleIndex: si, radiance)
        }
        _sampleIndex += Int(shBuffer.sqrtSamples)
    }
    
    func update() {
        switch _phase {
        case .initSamples:
            initOneRowOfSamples()
            if sh.isInit {
                _phase = .readCubemap
            }
        case .computeSH:
            updateCoefficientsForOneRowOfSamples()
            if _sampleIndex >= shBuffer.numSamples {
                sh.normalizeCoefficients()
                sh.computeIrradianceApproximationMatrices()
                _phase = .readyToRender
                dump6Irradiances()
            }
        default:
            break
        }
    }
    
    func readCubemapSamples(encoder: MTLRenderCommandEncoder) {
        if #available(iOS 12.0, *) {
            guard let probe = _anchor as? AREnvironmentProbeAnchor else {
                return
            }
            guard let tex = probe.environmentTexture else {
                return
            }
            encoder.setVertexBuffer(shBuffer.normalBuffer, offset: 0, index: 0)
            encoder.setVertexBuffer(shBuffer.radianceBuffer, offset: 0, index: 1)
            encoder.setVertexTexture(tex, index: 0)
            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: Int(shBuffer.numSamples))
            _phase = .computeSH
        } else {
            // Fallback on earlier versions
        }
    }
    
    /// For debugging the values obtained
    func dump6Irradiances() {
        let up = sh.getIrradianceApproximation(normal: float3(0, 1, 0))
        let down = sh.getIrradianceApproximation(normal: float3(0, -1, 0))
        let west = sh.getIrradianceApproximation(normal: float3(-1, 0, 0))
        let east = sh.getIrradianceApproximation(normal: float3(1, 0, 0))
        let south = sh.getIrradianceApproximation(normal: float3(0, 0, 1))
        let north = sh.getIrradianceApproximation(normal: float3(0, 0, -1))
        print("SH up: \(up)")
        print("SH down: \(down)")
        print("SH west: \(west)")
        print("SH east: \(east)")
        print("SH south: \(south)")
        print("SH north: \(north)")
    }
}
