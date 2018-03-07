//
//  SelfOrganizingMap.swift
//  SampleColorPalette
//
//  Created by David Gavilan on 2018/03/03.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import VidFramework
import simd

class SelfOrganizingMap: FilterChain {
    let radius: Float
    let startLearningRate: Float = 0.1
    private let lambda: Float
    private var somFilter: SelfOrganizingMapFilter?
    private var distanceFilter: DistanceFilter?
    private var trainingData: [LinearRGBA]
    private var numIterations: Int
    
    init(device: MTLDevice, library: MTLLibrary, width: Int, height: Int, numIterations: Int, trainingData: [LinearRGBA]) {
        self.numIterations = numIterations
        let s = Float(max(width, height))
        radius = 0.5 // half the image, assuming a square image
        lambda = Float(numIterations) / logf(radius * s)
        self.trainingData = trainingData
        super.init()
        let rgba16data = trainingData.map { return $0.rgba16U }
        var data: [UInt64] = []
        var remaining = width * height
        repeat {
            let n = min(trainingData.count, remaining)
            data.append(contentsOf: rgba16data.shuffled()[0..<n])
            remaining = remaining - n
        } while remaining > 0
        loopMode = .times(numIterations)
        // ABGR, red: minDistance, green: u, blue: v
        data = [UInt64](repeating: 0xFFFF00000000FFFF, count: width * height)
        //data[0] = 0xFFFFFFFF00000000 // top left -> red
        //data[width*height-1] = 0xFFFFFFFF00000000 // bottom right -> white
        //data[width-1] = 0xFFFFFFFF00000000 // top right -> yellow
        data[(height-1) * width] = 0xFFFFFFFF00000000 // bottom left -> magenta
        let target = LinearRGBA(r: 0, g: 0, b: 1, a: 1)
        let texture = Texture(device: device, id: "SelfOrganizingMap0", width: width, height: height, data: data, usage: [.shaderRead, .renderTarget])
        //let target = trainingData.randomElement()
        if let mtlTexture = texture.mtlTexture,
           let distanceFilter = DistanceFilter(device: device, library: library, input: mtlTexture, target: target.raw) {
            chain.append(distanceFilter)
            self.distanceFilter = distanceFilter
        }
        var minimum: MTLTexture?
        if let distOutput = distanceFilter?.output,
           let findMin = FindMinimumFilterChain(device: device, library: library, input: distOutput) {
            minimum = findMin.output
            append(findMin)
        }
        let somData = SelfOrganizingMapFilter.SomData(learningRate: startLearningRate, neighborhoodRadius: radius, target: target.raw)
        if let mtlTexture = texture.mtlTexture,
           let minTexture = minimum,
            let somFilter = SelfOrganizingMapFilter(device: device, library: library, input: mtlTexture, minimum: minTexture, data: somData) {
            //chain.append(somFilter)
            if let somOut = somFilter.output,
               let copyFilter = CopyTextureFilter(device: device, library: library, input: somOut, output: mtlTexture) {
                //chain.append(copyFilter)
            }
            self.somFilter = somFilter
        }
    }
    
    override func updateBuffers(_ syncBufferIndex: Int) {
        let target = trainingData.randomElement().raw
        print(target)
        distanceFilter?.target = target
        somFilter?.shaderData.target = target
        let s = -Float(step)
        somFilter?.shaderData.neighborhoodRadius = radius * exp(s/lambda)
        somFilter?.shaderData.learningRate = startLearningRate * exp(s/Float(numIterations))
        super.updateBuffers(syncBufferIndex)
    }
}

class SelfOrganizingMapFilter: TextureFilter {
    struct SomData {
        var learningRate: Float
        var neighborhoodRadius: Float
        var dummy0: Float
        var dummy1: Float
        var target: float4
        init(learningRate: Float, neighborhoodRadius: Float, target: float4) {
            self.learningRate = learningRate
            self.neighborhoodRadius = neighborhoodRadius
            self.target = target
            self.dummy0 = 0
            self.dummy1 = 0
        }
    }
    var shaderData: SomData
    
    init?(device: MTLDevice, library: MTLLibrary, input: MTLTexture, minimum: MTLTexture, data: SomData) {
        shaderData = data
        guard let vfn = library.makeFunction(name: "passThrough2DVertex"),
            let ffn = library.makeFunction(name: "passSelfOrganizingMap")
            else {
                NSLog("Failed to create shaders")
                return nil
        }
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vfn
        pipelineDescriptor.fragmentFunction = ffn
        pipelineDescriptor.colorAttachments[0].pixelFormat = input.pixelFormat
        pipelineDescriptor.sampleCount = input.sampleCount
        super.init(id: "SOMFilter", device: device, descriptor: pipelineDescriptor)
        let texDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: input.pixelFormat, width: input.width, height: input.height, mipmapped: false)
        texDescriptor.usage = [.shaderRead, .renderTarget]
        output = device.makeTexture(descriptor: texDescriptor)
        buffer = Renderer.createSyncBuffer(from: data, device: device)
        inputs = [input, minimum]
    }
    
    override func postRender() {
        // ping-pong through the textures
        if let tmp = output {
            output = inputs.first
            inputs[0] = tmp
        }
    }
    
    // this gets called when we need to update the buffers used by the GPU
    override func updateBuffers(_ syncBufferIndex: Int) {
        super.updateBuffers(syncBufferIndex)
        guard let contents = buffer?.contents() else {
            return
        }
        let data = contents.advanced(by: bufferOffset).assumingMemoryBound(to: SomData.self)
        memcpy(data, &shaderData, MemoryLayout<SomData>.size)
    }
}
