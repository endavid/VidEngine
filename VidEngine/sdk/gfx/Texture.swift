//
//  Texture.swift
//  VidEngine
//
//  Created by David Gavilan on 2017/05/29.
//  Copyright © 2017 David Gavilan. All rights reserved.
//

import MetalKit

public enum TextureError : Error {
    case
    ResourceNotFound, CouldNotBeCreated,
    CouldNotGetCGImage, CouldNotDownsample, NotAnImage,
    ExceededMaxTextureSize, UnsupportedSize
}

public struct Texture {
    // maximum size in pixels in a given dimension (bigger textures will crash)
    public static let maxSize : Int = 8192
    public let mtlTexture: MTLTexture?
    public let id: String
}
