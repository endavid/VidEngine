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

extension CGSize {
    @inline(__always)
    static func *(lhs: CGSize, rhs: CGFloat) -> CGSize {
        return CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
}

// We need NSURLSessionDownloadTask or something similar.
// Like most Cocoa APIs, MTKTextureLoader only operates on file URLs.
// http://stackoverflow.com/a/42460943/1765629
extension MTKTextureLoader {
    enum RemoteTextureLoaderError: Error {
        case noCachesDirectory
        case downloadFailed(URLResponse?)
    }
    
    // ref. https://developer.apple.com/library/content/samplecode/LargeImageDownsizing/
    private static func downsize(image: UIImage, scale: CGFloat) -> CGImage? {
        let destResolution = image.size * scale
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
    func newTexture(with uiImage: UIImage, options: [String : NSObject]? = nil, completionHandler: MTKTextureLoaderCallback) {
        if let cgImage = uiImage.cgImage {
            // use sync here, because async crashes. See stackoverflow
            let tex = try? self.newTexture(with: cgImage, options: options)
            completionHandler(tex, tex == nil ? TextureError.CouldNotBeCreated : nil)
        } else {
            completionHandler(nil, TextureError.CouldNotGetCGImage)
        }
    }
    
    // This may crash at the moment if the width of the texture is >8192 ...
    // > MTLTextureDescriptor has width (10000) greater than the maximum allowed size of 8192.
    func newTexture(withContentsOfRemote url: URL, options: [String : NSObject]? = nil, completionHandler: @escaping MTKTextureLoaderCallback) {
        let downloadTask = URLSession.shared.downloadTask(with: URLRequest(url: url)) { (maybeFileURL, maybeResponse, maybeError) in
            var anError: Error? = maybeError
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
                                let tex = try? self.newTexture(with: cgImage, options: options)
                                completionHandler(tex, tex == nil ? TextureError.CouldNotBeCreated : nil)
                                return
                            } else {
                                anError = TextureError.CouldNotDownsample
                            }
                        } else {
                            //return self.newTexture(with: uiImage, options: options, completionHandler: completionHandler)
                            return self.newTexture(withContentsOf: cachedFileURL, options: options, completionHandler: completionHandler)
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
}

class TextureLibrary {
    private var lib: [String: MTLTexture] = [:]
    
    func getTextureAsync(resource: String, bundle: Bundle, options: [String:NSObject]? = nil, addToCache: Bool, completion: @escaping (MTLTexture?, Error?) -> Void) {
        if let t = lib[resource] {
            completion(t, nil)
            return
        }
        guard let index = resource.range(of: ".", options: .backwards)?.lowerBound else {
            completion(nil, TextureError.ResourceNotFound)
            return
        }
        let name = resource.substring(to: index)
        let ext = resource.substring(from: resource.index(after: index))
        guard let url = bundle.url(forResource: name, withExtension: ext) else {
            completion(nil, TextureError.ResourceNotFound)
            return
        }
        getTextureAsync(id: resource, fileUrl: url, options: options, addToCache: addToCache, completion: completion)
    }
    
    func getTextureAsync(id: String, fileUrl: URL, options: [String:NSObject]?, addToCache: Bool, completion: @escaping (MTLTexture?, Error?) -> Void) {
        if let t = lib[id] {
            completion(t, nil)
            return
        }
        let textureLoader = MTKTextureLoader(device: RenderManager.sharedInstance.device)
        textureLoader.newTexture(withContentsOf: fileUrl, options: options) { [weak self] (texture, error) in
            if let t = texture {
                if addToCache {
                    self?.lib[id] = t
                }
                completion(t, nil)
            } else {
                if let desc = error?.localizedDescription {
                    NSLog(desc)
                }
                completion(nil, TextureError.CouldNotBeCreated)
            }
        }
    }
    
    func getTextureAsync(id: String, remoteUrl: URL, options: [String:NSObject]?, addToCache: Bool, completion: @escaping (MTLTexture?, Error?) -> Void) {
        if let t = lib[id] {
            completion(t, nil)
            return
        }
        let textureLoader = MTKTextureLoader(device: RenderManager.sharedInstance.device)
        textureLoader.newTexture(withContentsOfRemote: remoteUrl, options: options) { [weak self] (texture, error) in
            if let t = texture {
                if addToCache {
                    self?.lib[id] = t
                }
                completion(t, nil)
            } else {
                if let desc = error?.localizedDescription {
                    NSLog(desc)
                }
                completion(nil, TextureError.CouldNotBeCreated)
            }
        }
    }
    
    func remove(_ textureId: String) {
        lib.removeValue(forKey: textureId)
    }
    
    func clear() {
        lib.removeAll()
    }
}
