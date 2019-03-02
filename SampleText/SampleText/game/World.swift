//
//  World.swift
//  VidEngine
//
//  Created by David Gavilan on 8/20/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

import Foundation
import UIKit
import simd
import VidFramework

class World {
    var scene : Scene!
    
    // should be initialized after all the graphics are initialized
    init() {
        scene = GridScene(numRows: 12, numColumns: 20)
        initSprites()
        initTextDemo()
    }
    
    private func initSprites() {
        let sprite = SpritePrimitive2D()
        sprite.options = [.alignCenter]
        sprite.position = Vec3(-0.75, -0.75, 0)
        sprite.width = 40
        sprite.height = 20
        if let g = Group2D(maxNumOfSprites: 20) {
            g.append(sprite)
            scene.groups2D.append(g)
        }
        scene.queueAll()
    }
    
    private func initTextDemo() {
        let fontName = "HoeflerText-Regular"
        guard let font = UIFont(name: fontName, size: 72) else {
            NSLog("Font not found: \(fontName)")
            return
        }
        //let font = UIFont.systemFont(ofSize: 14)
        if let fontAtlas = try? FontAtlas.createFontAtlas(font: font, textureSize: 2048, archive: true) {
            let makeItStand = Quaternion(AngleAxis(angle: .pi / 2, axis: float3(1,0,0)))
            let tiltToOneSide = Quaternion(AngleAxis(angle: .pi / 4, axis: float3(0,1,0)))
            let prim = TextPrimitive(instanceCount: 1, font: fontAtlas, text: "Hello World! :)", fontSizeMeters: 1, enclosingFrame: CGRect(x: -2, y: -5, width: 4, height: 10))
            prim.transform.position = float3(0,0,12)
            prim.transform.rotation = tiltToOneSide * makeItStand
            prim.queue()
            self.scene?.primitives.append(prim)
            // debug the font atlas
            let debugPanel = PlanePrimitive(instanceCount: 1)
            debugPanel.lightingType = .UnlitTransparent
            debugPanel.transform = Transform(position: float3(0, 1.5, 18), scale: float3(1,1,1), rotation: makeItStand)
            debugPanel.albedoTexture = fontAtlas.fontTexture
            debugPanel.queue()
            self.scene?.primitives.append(debugPanel)
        } else {
            NSLog("Error initializing FontAtlas")
        }
    }
    
    func update(_ currentTime: CFTimeInterval) {
        scene.update(currentTime)
    }
}
