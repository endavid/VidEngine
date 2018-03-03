//
//  FilterChain.swift
//  VidFramework
//
//  Created by David Gavilan on 2018/02/28.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import Metal
import MetalKit

open class FilterChain {
    public enum LoopMode {
        case
        /// Apply only once
        once,
        ///
        times(Int),
        /// Repeat on every frame
        forever
    }
    public enum ExecutionMode {
        case
        /// Execute sequentially in the same frame
        immediateSequential,
        /// Execute one filter per frame
        acrossFrames
    }
    public var loopMode: LoopMode = .once
    // Only immediateSequential implemented atm
    private var executionMode: ExecutionMode = .immediateSequential
    public var chain: [TextureFilter] = []
    private var _step = 0
    public var step: Int {
        get {
            return _step
        }
    }
    public var isCompleted: Bool {
        get {
            switch loopMode {
            case .once:
                return _step >= 1
            case .times(let n):
                return _step >= n
            default:
                return false
            }
        }
    }
    public var inputs: [MTLTexture] {
        get {
            return chain.first?.inputs ?? []
        }
    }
    public var output: MTLTexture? {
        get {
            return chain.last?.output
        }
    }
    
    public init() {}
    
    public func queue() {
        let plugin : FilterPlugin? = Renderer.shared.getPlugin()
        plugin?.queue(self)
    }
    
    public func dequeue() {
        let p: FilterPlugin? = Renderer.shared.getPlugin()
        p?.dequeue(self)
    }
    
    public func append(_ filterChain: FilterChain) {
        chain.append(contentsOf: filterChain.chain)
    }
    
    // this gets called when we need to update the buffers used by the GPU
    open func updateBuffers(_ syncBufferIndex: Int) {
        _step += 1
        for f in chain {
            f.updateBuffers(syncBufferIndex)
        }
    }

}
