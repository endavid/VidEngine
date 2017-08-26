//
//  CoreText.swift
//  VidEngine
//
//  Created by Adam Nemecek on 8/26/17.
//  Copyright © 2017 David Gavilan. All rights reserved.
//

import CoreText

extension CFArrayEx where Element == CTLine {
    func glyphCount() -> Int {
        return lazy.map { $0.glyphCount }.sum()
    }

    init(frame : CTFrame) {
        self.init(ref : CTFrameGetLines(frame))
    }
}

extension CTLine {
    var glyphCount : Int {
        return CTLineGetGlyphCount(self)
    }

    var runs : CFArrayEx<CTRun> {
        return CFArrayEx(ref: CTLineGetGlyphRuns(self))
    }
}

extension CTRun {
    var glyphCount : Int {
        return CTRunGetGlyphCount(self)
    }

    var glyphs: [CGGlyph] {
        var ret = [CGGlyph](repeating: CGGlyph(), count: glyphCount)
        CTRunGetGlyphs(self, CFRange(), &ret)
        return ret
    }

    var positions : [CGPoint] {
        var ret = [CGPoint](repeating: CGPoint(), count: glyphCount)
        CTRunGetPositions(self, CFRange(), &ret)
        return ret
    }

    func imageBounds(ctx: CGContext, idx: Int) -> CGRect {
        return CTRunGetImageBounds(self, ctx, CFRange(location: idx, length: 1))
    }
}
