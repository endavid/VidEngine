//
//  Group2D.swift
//  VidFramework
//
//  Created by David Gavilan on 2018/03/24.
//  Copyright © 2018 David Gavilan. All rights reserved.
//

import MetalKit

/// Encapsulates a group of sprites that share the same
/// texture. A buffer is created on instantiation with the
/// maximum number of objects this group can hold (100 by default)
public class Group2D {
    public var texture: Texture?
    var sprites: [SpritePrimitive2D] = []
    var spriteVB: MTLBuffer
    var spriteIB: MTLBuffer
    let maxNumOfSprites: Int
    var spriteVBoffset: Int = 0

    public func queue() {
        let plugin : Primitive2DPlugin? = Renderer.shared.getPlugin()
        plugin?.queue(self)
    }

    public func dequeue() {
        let plugin : Primitive2DPlugin? = Renderer.shared.getPlugin()
        plugin?.dequeue(self)
    }

    public func append(_ sprite: SpritePrimitive2D) {
        if sprites.count == maxNumOfSprites {
            NSLog("Group2D is full: reached \(maxNumOfSprites)")
        } else {
            sprites.append(sprite)
        }
    }

    public init?(maxNumOfSprites: Int) {
        guard let device = Renderer.shared?.device else {
            return nil
        }
        // generate a large enough buffer to allow streaming vertices for 3 semaphore controlled frames
        // 4 vertices per sprite * max * triple buffer
        guard let vb = device.makeBuffer(length: Renderer.NumSyncBuffers * maxNumOfSprites * MemoryLayout<ColoredUnlitTexturedVertex>.size * 4, options: []) else {
            return nil
        }
        // we don't need to triple buffer this because it's going to be static
        // 6 indices per sprite
        guard let ib = device.makeBuffer(length: maxNumOfSprites * MemoryLayout<UInt16>.size * 6, options: []) else {
            return nil
        }
        spriteVB = vb
        spriteIB = ib
        self.maxNumOfSprites = maxNumOfSprites
        initSpriteIndexBuffer()
    }
    private func initSpriteIndexBuffer() {
        let ib = spriteIB.contents().advanced(by: 0).assumingMemoryBound(to: UInt16.self)
        for i in 0..<maxNumOfSprites {
            ib[6*i]   = UInt16(4*i)
            ib[6*i+1] = UInt16(4*i+2)
            ib[6*i+2] = UInt16(4*i+1)
            ib[6*i+3] = UInt16(4*i+3)
            ib[6*i+4] = UInt16(4*i+2)
            ib[6*i+5] = UInt16(4*i+1)
        }
    }
    func updateBuffers(_ syncBufferIndex: Int, camera: Camera) {
        spriteVBoffset = MemoryLayout<ColoredUnlitTexturedVertex>.size * maxNumOfSprites * 4 * syncBufferIndex
        updateSpriteBuffer(bounds: camera.bounds)
    }
    private func updateSpriteBuffer(bounds: CGRect) {
        let vb = spriteVB.contents().advanced(by: spriteVBoffset).assumingMemoryBound(to: ColoredUnlitTexturedVertex.self)
        let sx = 2 / Float(bounds.width)
        let sy = 2 / Float(bounds.height)
        for i in 0..<sprites.count {
            // expand vertices of sprites
            let sprite = sprites[i]
            let w = sprite.width
            let h = sprite.height
            var tx : Float = 0
            var ty : Float = 0
            if sprite.options.contains(.alignCenter) {
                tx = -0.5 * w
                ty = -0.5 * h
            } else if sprite.options.contains(.alignBottom) {
                tx = -sprite.width
            } else {
                ty = -sprite.height
            }
            var vertices = [
                Vec3(tx, ty, 0),
                Vec3(tx, ty + h, 0),
                Vec3(tx + w, ty, 0),
                Vec3(tx + w, ty + h, 0)
            ]
            if sprite.options.contains(.allowRotation) {
                let cosa = sprite.cosa
                let sina = sprite.sina
                for k in 0..<vertices.count {
                    let x = vertices[k].x
                    let y = vertices[k].y
                    vertices[k] = Vec3(
                        sx * (cosa * x - sina * y),
                        sy * (sina * x + cosa * y), 0)
                }
            } else {
                for k in 0..<vertices.count {
                    let x = vertices[k].x
                    let y = vertices[k].y
                    vertices[k] = Vec3(x * sx, y * sy, 0)
                }
            }
            // @todo set UV from texture atlas
            let u0 : Float = 0
            let u1 : Float = 1
            let v0 : Float = 1
            let v1 : Float = 0
            vb[4*i+0].position = sprite.position + vertices[0]
            vb[4*i+1].position = sprite.position + vertices[1]
            vb[4*i+2].position = sprite.position + vertices[2]
            vb[4*i+3].position = sprite.position + vertices[3]
            vb[4*i+0].uv = Vec2(u0, v0)
            vb[4*i+1].uv = Vec2(u0, v1)
            vb[4*i+2].uv = Vec2(u1, v0)
            vb[4*i+3].uv = Vec2(u1, v1)
            vb[4*i+0].color = Vec4(sprite.linearColor.raw)
            vb[4*i+1].color = Vec4(sprite.linearColor.raw)
            vb[4*i+2].color = Vec4(sprite.linearColor.raw)
            vb[4*i+3].color = Vec4(sprite.linearColor.raw)
        } // for all sprites
    } // updateSpriteBuffer
}
