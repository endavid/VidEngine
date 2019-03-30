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
    public enum DebugMode {
        case
        none,
        sphere,
        samples
    }
    enum Phase {
        case
        initSamples,
        readCubemap,
        computeSH,
        readyToRender
    }
    struct Instance {
        var transform: Transform
        var tonemap: float4
    }
    let irradianceBlendFrameCount = 30
    let identifier: UUID
    let shBuffer: SHBuffer
    let sh: SphericalHarmonics
    var vertexBuffer: MTLBuffer!
    var indexBuffer: MTLBuffer!
    var instanceBuffer: MTLBuffer!
    var irradianceBuffer: MTLBuffer!
    var bufferOffset = 0
    fileprivate var _phase: Phase
    fileprivate var _sampleIndex: Int
    fileprivate var _envmap: MTLTexture?
    fileprivate var _debugSphere: Primitive?
    fileprivate var _debugDots: Dots3D?
    fileprivate var _debugBB: WireCube?
    fileprivate var _instance: Instance
    fileprivate var _previousIrradiances: [float4x4]
    fileprivate var _irradianceBlendStep = 30
    
    var transform: Transform {
        get {
            return _instance.transform
        }
        set {
            _instance.transform = newValue
        }
    }
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
    var environmentTexture: MTLTexture? {
        get {
            return _envmap
        }
        set {
            if _phase != .initSamples {
                _phase = .readCubemap
            }
            _envmap = newValue
            _debugSphere?.albedoTexture = _envmap
            _previousIrradiances = blendIrradianceMatrices()
            _irradianceBlendStep = irradianceBlendFrameCount
        }
    }
    public var debug: DebugMode {
        get {
            if _debugSphere != nil {
                return DebugMode.sphere
            }
            if _debugDots != nil {
                return DebugMode.samples
            }
            return DebugMode.none
        }
        set {
            switch newValue {
            case .sphere:
                if _debugSphere == nil {
                    _debugSphere = createDebugSphere()
                    _debugSphere?.queue()
                    _debugDots?.dequeue()
                }
            case .samples:
                if _debugDots == nil {
                    _debugDots = createDebugDots()
                    _debugDots?.queue()
                    _debugSphere?.dequeue()
                }
            default:
                _debugDots?.dequeue()
                _debugSphere?.dequeue()
                _debugDots = nil
                _debugSphere = nil
            }
        }
    }
    public var showBoundingBox: Bool {
        get {
            return _debugBB != nil
        }
        set {
            if newValue {
                if _debugBB == nil {
                    _debugBB = createDebugBoundingBox()
                    _debugBB?.queue()
                }
            } else {
                _debugBB?.dequeue()
                _debugBB = nil
            }
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
        _debugBB?.dequeue()
        _debugDots?.dequeue()
        _debugSphere?.dequeue()
        if let plugin: ARPlugin? = Renderer.shared?.getPlugin(),
            let p = plugin {
            p.dequeue(self)
        }
    }
    
    #if DEBUG
    deinit {
        // Just making sure that we clean up properly!
        print("Removing probe \(identifier)")
    }
    #endif
    
    public init(position: float3, extent: float3, session: ARSession) {
        if #available(iOS 12.0, *) {
            let probeAnchor = AREnvironmentProbeAnchor(name: "sceneProbe", transform: Transform(position: position).toMatrix4(), extent: extent)
            session.add(anchor: probeAnchor)
            identifier = probeAnchor.identifier
            print(probeAnchor)
        } else {
            identifier = UUID()
            NSLog("Environment Probe not available <iOS12.0")
        }
        let device = Renderer.shared.device!
        let t = Transform(position: position, scale: extent)
        let s: Float = 2.0 / .pi // divide by .pi to convert irradiance to radiance
        let tonemap = float4(s, s, s, 1.0)
        _instance = Instance(transform: t, tonemap: tonemap)
        shBuffer = SHBuffer(device: Renderer.shared.device, numBands: 3, sqrtSamples: 100)
        sh = SphericalHarmonics(shBuffer)
        _previousIrradiances = shBuffer.irradiances
        vertexBuffer = CubePrimitive.createCubeVertexBuffer()
        indexBuffer = CubePrimitive.createCubeIndexBuffer()
        instanceBuffer = Renderer.createSyncBuffer(from: _instance, device: device)
        instanceBuffer.label = "shlightTransform"
        irradianceBuffer = Renderer.createBuffer(from: _previousIrradiances, device: device)
        irradianceBuffer.label = "irradiances"
        _phase = .initSamples
        _sampleIndex = 0
        super.init()
        initDefaultLight()
    }
    
    private func initDefaultLight() {
        // gray with some blue on top, and dark gray on bottom
        let s: Float = .pi / 4
        shBuffer.setCoefficient(i: 0, s * Vec3(1.489313, 1.534833, 1.534833))
        shBuffer.setCoefficient(i: 1, s * Vec3(0.004517199, 0.003428788, 0.003428788))
        shBuffer.setCoefficient(i: 2, s * Vec3(0.05805949, 0.1300996, 0.1300996))
        shBuffer.setCoefficient(i: 3, s * Vec3(-0.0004402802, -0.0005989054, -0.0005989054))
        shBuffer.setCoefficient(i: 4, s * Vec3(-0.001946267, -0.001821843, -0.001821843))
        shBuffer.setCoefficient(i: 5, s * Vec3(-0.001653977, -0.003708838, -0.003708838))
        shBuffer.setCoefficient(i: 6, s * Vec3(-0.2170652, -0.1401097, -0.1401097))
        shBuffer.setCoefficient(i: 7, s * Vec3(0.00438555, 0.004153608, 0.004153608))
        shBuffer.setCoefficient(i: 8, s * Vec3(-0.0002386605, -0.0005158358, -0.0005158358))
        sh.computeIrradianceApproximationMatrices()
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
                _irradianceBlendStep = 0
                //dump6Irradiances()
            }
        default:
            break
        }
    }
    
    func readCubemapSamples(encoder: MTLRenderCommandEncoder) {
        guard let tex = _envmap else {
            return
        }
        encoder.setVertexBuffer(shBuffer.normalBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(shBuffer.radianceBuffer, offset: 0, index: 1)
        encoder.setVertexTexture(tex, index: 0)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: Int(shBuffer.numSamples))
        _phase = .computeSH
        _sampleIndex = 0
    }
    
    func draw(encoder: MTLRenderCommandEncoder) {
        encoder.drawIndexedPrimitives(type: .triangle, indexCount: CubePrimitive.numIndices, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
    }
    
    fileprivate func createDebugSphere() -> Primitive {
        let sphere = EnvironmentSphere(isInterior: false, widthSegments: 8, heightSegments: 8)
        sphere.transform = Transform(position: self.transform.position, scale: 0.1)
        sphere.albedoTexture = environmentTexture
        return sphere
    }
    
    fileprivate func createDebugDots() -> Dots3D {
        let t = Transform(position: transform.position, scale: 0.05)
        let dots = Dots3D(transform: t, dotSize: 3, vertexBuffer: shBuffer.normalBuffer, colorBuffer: shBuffer.radianceBuffer, vertexCount: Int(shBuffer.numSamples))
        return dots
    }
    
    fileprivate func createDebugBoundingBox() -> WireCube {
        let cube = WireCube(instanceCount: 1)
        cube.transform = transform
        cube.color = LinearRGBA(UIColor.green)
        return cube
    }
    
    /// For debugging the values obtained
    func dump6Irradiances() {
        print("Updated probe \(identifier.uuidString)")
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
    
    private func blendIrradianceMatrices() -> [float4x4] {
        let a = Float(_irradianceBlendStep) / Float(irradianceBlendFrameCount)
        var out: [float4x4] = []
        for i in 0..<3 {
            let m = shBuffer.irradiances[i] * a + (1 - a) * _previousIrradiances[i]
            out.append(m)
        }
        return out
    }
    
    // this gets called when we need to update the buffers used by the GPU
    func updateBuffers(_ syncBufferIndex: Int) {
        if _irradianceBlendStep <= irradianceBlendFrameCount {
            updateIrradianceBuffer()
            _irradianceBlendStep += 1
        }
        bufferOffset = MemoryLayout<Instance>.size * syncBufferIndex
        let b = instanceBuffer.contents()
        let data = b.advanced(by: bufferOffset).assumingMemoryBound(to: Float.self)
        memcpy(data, &_instance, MemoryLayout<Transform>.size)
    }
    
    private func updateIrradianceBuffer() {
        let blend = blendIrradianceMatrices()
        let b = irradianceBuffer.contents()
        let data = b.assumingMemoryBound(to: float4x4.self)
        for i in 0..<3 {
            data[i] = blend[i]
        }
    }
    
}
