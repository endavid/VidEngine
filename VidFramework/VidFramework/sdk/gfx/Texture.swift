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

public enum TextureType {
    case
    flat,
    cubemap,
    volume
}

/// The layout of a given cubemap texture
enum TextureCubeLayout {
    // https://docs.unity3d.com/Manual/class-Cubemap.html
    case
    crossHorizontal,
    crossVertical,
    horizontal,
    // also supported through MTKTextureLoaderCubeLayoutVertical, but none of the others are.
    vertical
}

public struct Texture {
    // maximum size in pixels in a given dimension (bigger textures will crash)
    public static let maxSize : Int = 8192
    public let mtlTexture: MTLTexture?
    /// The rendering pipeline expects linear color everywhere
    /// If you are using a non bgra8Unorm_srgb texture, the texture
    /// is assumed to be in linear RGB. Before displaying,
    /// the gamma will be applied.
    public let isLinear: Bool
    public let id: String
    public init(id: String, mtlTexture: MTLTexture) {
        self.id = id
        self.mtlTexture = mtlTexture
        self.isLinear = Texture.guessLinear(mtlTexture.pixelFormat)
    }
    /// If you are using a non bgra8Unorm_srgb texture, but its contents
    /// are in sRGB, set isLinear to false, so it's converted to
    /// linear color space in the appropriate places, before displaying
    /// because the backbuffer expects things in linear RGB
    /// (the backbuffer is set to bgra8Unorm_srgb so it applies the
    /// gamma before displaying)
    public init(id: String, mtlTexture: MTLTexture, isLinear: Bool) {
        self.id = id
        self.mtlTexture = mtlTexture
        self.isLinear = isLinear
    }
    
    static func guessLinear(_ pixelFormat: MTLPixelFormat) -> Bool {
        switch pixelFormat {
        case .bgra8Unorm_srgb:
            return false
        case .rgba8Unorm_srgb:
            return false
        default:
            return true
        }
    }

}

public struct TextureLoadOptions {
    /// Additional texture loading steps. See apple-reference-documentation://ts1661985
    let options: [MTKTextureLoader.Option : Any]?
    let type: TextureType
    init(options: [MTKTextureLoader.Option : Any]?, type: TextureType = .flat) {
        self.options = options
        self.type = type
    }
}

// We need NSURLSessionDownloadTask or something similar.
// Like most Cocoa APIs, MTKTextureLoader only operates on file URLs.
// http://stackoverflow.com/a/42460943/1765629
extension MTKTextureLoader {
    enum RemoteTextureLoaderError: Swift.Error {
        case noCachesDirectory
        case downloadFailed(URLResponse?)
    }
    
    // ref. https://developer.apple.com/library/content/samplecode/LargeImageDownsizing/
    private static func downsize(image: UIImage, scale: CGFloat) -> CGImage? {
        let destResolution = CGSize(width: Int(image.size.width * scale), height: Int(image.size.height * scale))
        let kSourceImageTileSizeMB : CGFloat = 40.0 // The tile size will be (x)MB of uncompressed image data
        let pixelsPerMB = 262144
        let tileTotalPixels = kSourceImageTileSizeMB * CGFloat(pixelsPerMB)
        let destSeemOverlap : CGFloat = 2.0 // the numbers of pixels to overlap the seems where tiles meet.
        
        // create an offscreen bitmap context that will hold the output image
        // pixel data, as it becomes available by the downscaling routine.
        // use the RGB colorspace as this is the colorspace iOS GPU is optimized for.
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        // create the output bitmap context
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let destContext = CGContext(data: nil, width: Int(destResolution.width), height: Int(destResolution.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            NSLog("failed to create the output bitmap context!")
            return nil
        }
        // now define the size of the rectangle to be used for the
        // incremental blits from the input image to the output image.
        // we use a source tile width equal to the width of the source
        // image due to the way that iOS retrieves image data from disk.
        // iOS must decode an image from disk in full width 'bands', even
        // if current graphics context is clipped to a subrect within that
        // band. Therefore we fully utilize all of the pixel data that results
        // from a decoding opertion by achnoring our tile size to the full
        // width of the input image.
        var sourceTile = CGRect()
        sourceTile.size.width = image.size.width
        // the source tile height is dynamic. Since we specified the size
        // of the source tile in MB, see how many rows of pixels high it
        // can be given the input image width.
        sourceTile.size.height = floor( tileTotalPixels / sourceTile.size.width )
        print("source tile size: \(sourceTile.size)")
        sourceTile.origin.x = 0.0
        // the output tile is the same proportions as the input tile, but
        // scaled to image scale.
        var destTile = CGRect()
        destTile.size.width = destResolution.width
        destTile.size.height = sourceTile.size.height * scale
        destTile.origin.x = 0.0
        print("dest tile size: \(destTile.size)")
        // the source seem overlap is proportionate to the destination seem overlap.
        // this is the amount of pixels to overlap each tile as we assemble the ouput image.
        let sourceSeemOverlap : CGFloat = floor( ( destSeemOverlap / destResolution.height ) * image.size.height )
        print("dest seem overlap: \(destSeemOverlap), source seem overlap: \(sourceSeemOverlap)")
        // calculate the number of read/write opertions required to assemble the
        // output image.
        var iterations = Int( image.size.height / sourceTile.size.height )
        // if tile height doesn't divide the image height evenly, add another iteration
        // to account for the remaining pixels.
        let remainder = Int(image.size.height) % Int(sourceTile.size.height)
        if remainder > 0 {
            iterations += 1
        }
        // add seem overlaps to the tiles, but save the original tile height for y coordinate calculations.
        let sourceTileHeightMinusOverlap = sourceTile.size.height
        sourceTile.size.height += sourceSeemOverlap
        destTile.size.height += destSeemOverlap
        print("beginning downsize. iterations: \(iterations), tile height: \(sourceTile.size.height), remainder height: \(remainder)")
        for y in 0..<iterations {
            // create an autorelease pool to catch calls to -autorelease made within the downsize loop.
            autoreleasepool {
                print("iteration \(y+1) of \(iterations)")
                sourceTile.origin.y = CGFloat(y) * sourceTileHeightMinusOverlap + sourceSeemOverlap
                destTile.origin.y = ( destResolution.height ) - ( CGFloat( y + 1 ) * sourceTileHeightMinusOverlap * scale + destSeemOverlap )
                // create a reference to the source image with its context clipped to the argument rect.
                if let sourceTileImage = image.cgImage?.cropping( to: sourceTile ) {
                    // if this is the last tile, its size may be smaller than the source tile height.
                    // adjust the dest tile size to account for that difference.
                    if  y == iterations - 1 && remainder > 0 {
                        var dify = destTile.size.height
                        destTile.size.height = CGFloat( sourceTileImage.height ) * scale
                        dify -= destTile.size.height
                        destTile.origin.y += dify
                    }
                    // read and write a tile sized portion of pixels from the input image to the output image.
                    destContext.draw(sourceTileImage, in: destTile, byTiling: false)
                }
                /* while CGImageCreateWithImageInRect lazily loads just the image data defined by the argument rect,
                 that data is finally decoded from disk to mem when CGContextDrawImage is called. sourceTileImageRef
                 maintains internally a reference to the original image, and that original image both, houses and
                 caches that portion of decoded mem. Thus the following call to release the source image. */
                //[sourceImage release];
                // http://en.swifter.tips/autoreleasepool/
                // drain will be called
                // to free all objects that were sent -autorelease within the scope of this loop.
            }
            // we reallocate the source image after the pool is drained since UIImage -imageNamed
            // returns us an autoreleased object.
            /*
             if  y < iterations - 1  {
             sourceImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:kImageFilename ofType:nil]];
             [self performSelectorOnMainThread:@selector(updateScrollView:) withObject:nil waitUntilDone:YES];
             }*/
        }
        print("downsize complete.")
        // create a CGImage from the offscreen image context
        return destContext.makeImage()
    }
    
    // http://stackoverflow.com/q/42567140/1765629
    // https://forums.developer.apple.com/thread/73478
    func newTexture(with uiImage: UIImage, options: TextureLoadOptions?, completionHandler: MTKTextureLoader.Callback) {
        if let cgImage = uiImage.cgImage {
            if options?.type == .cubemap {
                let tex = newCubemapTexture(with: cgImage)
                completionHandler(tex, nil)
            } else {
                // use sync here, because async crashes. See stackoverflow
                let tex = try? self.newTexture(cgImage: cgImage, options: options?.options)
                completionHandler(tex, tex == nil ? TextureError.CouldNotBeCreated : nil)
            }
        } else {
            completionHandler(nil, TextureError.CouldNotGetCGImage)
        }
    }
    
    func newCubemapTexture(posX: UIImage, negX: UIImage, posY: UIImage, negY: UIImage, posZ: UIImage, negZ: UIImage, completionHandler: MTKTextureLoader.Callback) {
        if let cgPosX = posX.cgImage,
            let cgNegX = negX.cgImage,
            let cgPosY = posY.cgImage,
            let cgNegY = negY.cgImage,
            let cgPosZ = posZ.cgImage,
            let cgNegZ = negZ.cgImage
        {
            let tex = newCubemapTexture(posX: cgPosX, negX: cgNegX, posY: cgPosY, negY: cgNegY, posZ: cgPosZ, negZ: cgNegZ)
            completionHandler(tex, nil)
        } else {
            completionHandler(nil, TextureError.CouldNotGetCGImage)
        }
    }
    
    /// Guess the layout from the aspect ratio, and return the size as well
    private static func getTextureCubeLayout(cgImage: CGImage) -> (TextureCubeLayout, Int) {
        let w = cgImage.width
        let h = cgImage.height
        if w > 5 * h {
            return (.horizontal, h)
        }
        if h > 5 * w {
            return (.vertical, w)
        }
        if 3 * w >= 4 * h {
            return (.crossHorizontal, w/4)
        }
        return (.crossVertical, h/4)
    }
    
    private static func getTransformsForLayout(_ layout: TextureCubeLayout, size: CGFloat) -> [CGRect] {
        
        switch layout {
        case .crossHorizontal:
            return [CGRect(x: 0, y: -size, width: size, height: size), // +X
                CGRect(x: -2 * size, y: -size, width: size, height: size), // -X
                CGRect(x: 2 * size, y: 0, width: -size, height: -size), // +Y
                CGRect(x: 2 * size, y: -2 * size, width: -size, height: -size), // -Y
                CGRect(x: -3 * size, y: -size, width: size, height: size), // +Z
                CGRect(x: -size, y: -size, width: size, height: size)] // -Z
        case .crossVertical:
            return [CGRect(x: 0, y: -2 * size, width: size, height: size), // +X
                CGRect(x: -2 * size, y: -2 * size, width: size, height: size), // -X
                CGRect(x: 2 * size, y: 0, width: -size, height: -size), // +Y
                CGRect(x: 2 * size, y: -2 * size, width: -size, height: -size), // -Y
                CGRect(x: 2 * size, y: -3 * size, width: -size, height: -size), // +Z
                CGRect(x: -size, y: -2 * size, width: size, height: size)] // -Z
        case .horizontal:
            return [CGRect(x: 0, y: 0, width: size, height: size), // +X
                CGRect(x: -size, y: 0, width: size, height: size), // -X
                CGRect(x: -2 * size, y: 0, width: size, height: size), // +Y
                CGRect(x: -3 * size, y: 0, width: size, height: size), // -Y
                CGRect(x: -4 * size, y: 0, width: size, height: size), // +Z
                CGRect(x: -5 * size, y: 0, width: size, height: size)] // -Z
        case .vertical:
            return [CGRect(x: 0, y: 0, width: size, height: size), // +X
                CGRect(x: -size, y: -size, width: size, height: size), // -X
                CGRect(x: -size, y: -2 * size, width: size, height: size), // +Y
                CGRect(x: -size, y: -3 * size, width: size, height: size), // -Y
                CGRect(x: -size, y: -4 * size, width: size, height: size), // +Z
                CGRect(x: -size, y: -5 * size, width: size, height: size)] // -Z
        }
    }
    
    
    private static func dataFromCgImage(_ cgImage: CGImage, region: CGRect) -> Array<UInt8> {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var rawData = Array<UInt8>(repeating: 0, count: Int(region.width * region.height * 4))
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        // width & height are signed to allow mirroring transforms
        // but .width & .height normalizes them (= abs)
        let w = region.width
        let h = region.height
        if let context = CGContext(data: &rawData, width: Int(w), height: Int(h), bitsPerComponent: 8, bytesPerRow: Int(4 * w), space: colorSpace, bitmapInfo: bitmapInfo.rawValue) {
            // to retrieve the size, use region.size!
            let sx = CGFloat(cgImage.width) / region.size.width
            let sy = CGFloat(cgImage.height) / region.size.height
            context.translateBy(x: region.origin.x, y: region.origin.y)
            context.scaleBy(x: sx, y: sy)
            context.draw(cgImage,
                         in: CGRect(x: 0, y: 0, width: w, height: h),
                         byTiling: true)
        }
        return rawData
    }
    
    func newCubemapTexture(with cgImage: CGImage) -> MTLTexture? {
        let layout = MTKTextureLoader.getTextureCubeLayout(cgImage: cgImage)
        let size = layout.1
        let textureDescriptor = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .rgba8Unorm_srgb, size: size, mipmapped: false)
        guard let texture = self.device.makeTexture(descriptor: textureDescriptor) else {
            return nil
        }
        let region = MTLRegionMake2D(0, 0, size, size)
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * size
        let bytesPerImage = bytesPerRow * size
        let ts = MTKTextureLoader.getTransformsForLayout(layout.0, size: CGFloat(size))
        // Order: +X, -X, +Y, -Y, +Z, -Z
        //  @see `MTLTextureType` https://developer.apple.com/documentation/metal/mtltexturetype
        //  @see https://docs.unity3d.com/Manual/class-Cubemap.html
        for slice in 0..<6 {
            let portion = ts[slice]
            let data = MTKTextureLoader.dataFromCgImage(cgImage, region: portion)
            texture.replace(region: region, mipmapLevel: 0, slice: slice,
                            withBytes: data,
                            bytesPerRow: bytesPerRow, bytesPerImage: bytesPerImage)
        }
        return texture
    }
    
    func newCubemapTexture(posX: CGImage, negX: CGImage, posY: CGImage, negY: CGImage, posZ: CGImage, negZ: CGImage) -> MTLTexture? {
        let size = posX.width
        let textureDescriptor = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .rgba8Unorm_srgb, size: size, mipmapped: false)
        guard let texture = self.device.makeTexture(descriptor: textureDescriptor) else {
            return nil
        }
        let region = MTLRegionMake2D(0, 0, size, size)
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * size
        let bytesPerImage = bytesPerRow * size
        let images = [posX, negX, posY, negY, posZ, negZ]
        let portion = CGRect(x: 0, y: 0, width: size, height: size)
        for slice in 0..<6 {
            let img = images[slice]
            let data = MTKTextureLoader.dataFromCgImage(img, region: portion)
            texture.replace(region: region, mipmapLevel: 0, slice: slice,
                            withBytes: data,
                            bytesPerRow: bytesPerRow, bytesPerImage: bytesPerImage)
        }
        return texture
    }
    
    
    /// Loads remote image, caching the URL, and downsampling the image
    /// if any ot its dimensions is greated than 8192 pixels
    func newTexture(withContentsOfRemote url: URL, options: TextureLoadOptions?, completionHandler: @escaping MTKTextureLoader.Callback) {
        let downloadTask = URLSession.shared.downloadTask(with: URLRequest(url: url)) { (maybeFileURL, maybeResponse, maybeError) in
            var anError: Swift.Error? = maybeError
            if let tempURL = maybeFileURL, let response = maybeResponse {
                if let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
                    let cachesURL = URL(fileURLWithPath: cachePath, isDirectory: true)
                    let cachedFileURL = cachesURL.appendingPathComponent(response.suggestedFilename ?? NSUUID().uuidString)
                    try? FileManager.default.moveItem(at: tempURL, to: cachedFileURL)
                    if let uiImage = UIImage(contentsOfFile: cachedFileURL.path) {
                        NSLog("Image size: \(uiImage.size.width)x\(uiImage.size.height)")
                        let maxDim = CGFloat(Texture.maxSize)
                        if uiImage.size.width > maxDim || uiImage.size.height > maxDim {
                            let scale = uiImage.size.width > maxDim ? maxDim / uiImage.size.width : maxDim / uiImage.size.height
                            if let cgImage = MTKTextureLoader.downsize(image: uiImage, scale: scale) {
                                if options?.type == .cubemap {
                                    let tex = self.newCubemapTexture(with: cgImage)
                                    completionHandler(tex, nil)
                                } else {
                                    let tex = try? self.newTexture(cgImage: cgImage, options: options?.options)
                                    completionHandler(tex, tex == nil ? TextureError.CouldNotBeCreated : nil)
                                }
                                return
                            } else {
                                anError = TextureError.CouldNotDownsample
                            }
                        } else if options?.type == .cubemap {
                            return self.newTexture(with: uiImage, options: options, completionHandler: completionHandler)
                        } else {
                            return self.newTexture(URL: cachedFileURL, options: options?.options, completionHandler: completionHandler)
                        }
                    } else {
                        anError = TextureError.NotAnImage
                    }
                } else {
                    anError = RemoteTextureLoaderError.noCachesDirectory
                }
            } else {
                anError = RemoteTextureLoaderError.downloadFailed(maybeResponse)
            }
            completionHandler(nil, anError)
        }
        downloadTask.resume()
    }
    
    func newTexture(withContentsOf fileUrl: URL, options: TextureLoadOptions?, completionHandler: @escaping MTKTextureLoader.Callback) {
        if options?.type == .cubemap {
            if let data = try? Data(contentsOf: fileUrl),
                let uiImage = UIImage(data: data) {
                self.newTexture(with: uiImage, options: options, completionHandler: completionHandler)
            } else {
                completionHandler(nil, TextureError.CouldNotBeCreated)
            }
        } else {
            self.newTexture(URL: fileUrl, options: options?.options, completionHandler: completionHandler)
        }
    }
    
    func newTexture(posX: URL, negX: URL, posY: URL, negY: URL, posZ: URL, negZ: URL, completionHandler: @escaping MTKTextureLoader.Callback) {
        if let dataPosX = try? Data(contentsOf: posX),
            let dataNegX = try? Data(contentsOf: negX),
            let dataPosY = try? Data(contentsOf: posY),
            let dataNegY = try? Data(contentsOf: negY),
            let dataPosZ = try? Data(contentsOf: posZ),
            let dataNegZ = try? Data(contentsOf: negZ),
            let uiPosX = UIImage(data: dataPosX),
            let uiNegX = UIImage(data: dataNegX),
            let uiPosY = UIImage(data: dataPosY),
            let uiNegY = UIImage(data: dataNegY),
            let uiPosZ = UIImage(data: dataPosZ),
            let uiNegZ = UIImage(data: dataNegZ)
        {
            self.newCubemapTexture(posX: uiPosX, negX: uiNegX, posY: uiPosY, negY: uiNegY, posZ: uiPosZ, negZ: uiNegZ, completionHandler: completionHandler)
        } else {
            completionHandler(nil, TextureError.CouldNotBeCreated)
        }
    }
}

public class TextureLibrary {
    private var lib: [String: MTLTexture] = [:]
    
    private func getUrl(forResource resource: String, bundle: Bundle) -> URL? {
        guard let index = resource.range(of: ".", options: .backwards)?.lowerBound else {
            return nil
        }
        let name = resource.prefix(upTo: index)
        let ext = resource.suffix(from: resource.index(after: index))
        return bundle.url(forResource: String(name), withExtension: String(ext))
    }
    
    public func getTextureAsync(resource: String, bundle: Bundle, options: TextureLoadOptions?, addToCache: Bool, completion: @escaping (MTLTexture?, Error?) -> Void) {
        if let t = lib[resource] {
            completion(t, nil)
            return
        }
        guard let url = getUrl(forResource: resource, bundle: bundle) else {
            completion(nil, TextureError.ResourceNotFound)
            return
        }
        getTextureAsync(id: resource, fileUrl: url, options: options, addToCache: addToCache, completion: completion)
    }
    
    public func getTextureAsync(id: String, posX: String, negX: String, posY: String, negY: String, posZ: String, negZ: String, bundle: Bundle, addToCache: Bool, completion: @escaping (MTLTexture?, Error?) -> Void) {
        if let t = lib[id] {
            completion(t, nil)
            return
        }
        guard let urlPosX = getUrl(forResource: posX, bundle: bundle),
            let urlNegX = getUrl(forResource: negX, bundle: bundle),
            let urlPosY = getUrl(forResource: posY, bundle: bundle),
            let urlNegY = getUrl(forResource: negY, bundle: bundle),
            let urlPosZ = getUrl(forResource: posZ, bundle: bundle),
            let urlNegZ = getUrl(forResource: negZ, bundle: bundle)
            else {
                completion(nil, TextureError.ResourceNotFound)
                return
        }
        getTextureAsync(id: id, posX: urlPosX, negX: urlNegX, posY: urlPosY, negY: urlNegY, posZ: urlPosZ, negZ: urlNegZ, addToCache: addToCache, completion: completion)
    }
    
    private func processNewTexture(id: String, addToCache: Bool, texture: MTLTexture?, error: Error?, completion: @escaping (MTLTexture?, Error?) -> Void) {
        if let t = texture {
            if addToCache {
                self.lib[id] = t
            }
            completion(t, nil)
        } else {
            if let desc = error?.localizedDescription {
                NSLog(desc)
            }
            completion(nil, TextureError.CouldNotBeCreated)
        }
    }
    
    public func getTextureAsync(id: String, fileUrl: URL, options: TextureLoadOptions?, addToCache: Bool, completion: @escaping (MTLTexture?, Error?) -> Void) {
        if let t = lib[id] {
            completion(t, nil)
            return
        }
        guard let device = Renderer.shared.device else {
            completion(nil, RendererError.MissingDevice)
            return
        }
        let textureLoader = MTKTextureLoader(device: device)
        textureLoader.newTexture(withContentsOf: fileUrl, options: options) { [weak self] (texture, error) in
            self?.processNewTexture(id: id, addToCache: addToCache, texture: texture, error: error, completion: completion)
        }
    }
    
    public func getTextureAsync(id: String, remoteUrl: URL, options: TextureLoadOptions?, addToCache: Bool, completion: @escaping (MTLTexture?, Error?) -> Void) {
        if let t = lib[id] {
            completion(t, nil)
            return
        }
        guard let device = Renderer.shared.device else {
            completion(nil, RendererError.MissingDevice)
            return
        }
        let textureLoader = MTKTextureLoader(device: device)
        textureLoader.newTexture(withContentsOfRemote: remoteUrl, options: options) { [weak self] (texture, error) in
            self?.processNewTexture(id: id, addToCache: addToCache, texture: texture, error: error, completion: completion)
        }
    }
    
    public func getTextureAsync(id: String, posX: URL, negX: URL, posY: URL, negY: URL, posZ: URL, negZ: URL, addToCache: Bool, completion: @escaping (MTLTexture?, Error?) -> Void) {
        if let t = lib[id] {
            completion(t, nil)
            return
        }
        guard let device = Renderer.shared.device else {
            completion(nil, RendererError.MissingDevice)
            return
        }
        let textureLoader = MTKTextureLoader(device: device)
        textureLoader.newTexture(posX: posX, negX: negX, posY: posY, negY: negY, posZ: posZ, negZ: negZ) { [weak self] (texture, error) in
            self?.processNewTexture(id: id, addToCache: addToCache, texture: texture, error: error, completion: completion)
        }
    }
    
    public func remove(_ textureId: String) {
        lib.removeValue(forKey: textureId)
    }
    
    public func clear() {
        lib.removeAll()
    }
}
