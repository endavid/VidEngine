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
    var completed = false
    public var isCompleted: Bool {
        get {
            return completed
        }
    }
    public var input: MTLTexture? {
        get {
            return chain.first?.input
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
}
