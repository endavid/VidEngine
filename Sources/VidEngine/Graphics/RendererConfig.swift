//
//  RendererConfig.swift
//  VidEngine
//
//  Created by David Gavilan Ruiz on 20/10/2026.
//

/// Configuration of the renderer. If you disable unlit opaque, unlit primitives won't render.
public struct RendererConfig: OptionSet, Sendable {
    public static let basic: RendererConfig = [.litOpaque, .unlitOpaque, .unlitTransparency]
    
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let litOpaque = Self(rawValue: 1 << 0)
    public static let unlitOpaque = Self(rawValue: 1 << 1)
    public static let unlitTransparency = Self(rawValue: 1 << 2)
}
