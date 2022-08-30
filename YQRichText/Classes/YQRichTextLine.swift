//
//  YQRichTextLine.swift
//  YQRichText
//
//  Created by CYQ on 2022/8/30.
//

import UIKit

class YQRichTextLine {
    
    let ctLine: CTLine
    
    let position: CGPoint
    
    let range: NSRange
    
    let lineWidth: CGFloat
    
    let ascent: CGFloat
    
    let descent: CGFloat
    
    let leading: CGFloat
    
    let bounds: CGRect
    
    private(set) var attachments: [YQRichTextAttachment] = []
    private(set) var attachmentRanges: [NSRange] = []
    private(set) var attachmentRects: [CGRect] = []
    
    init(ctLine: CTLine, position: CGPoint) {
        self.ctLine = ctLine
        self.position = position
        
        let ctRange = CTLineGetStringRange(ctLine)
        self.range = NSRange(location: ctRange.location, length: ctRange.length)
        
        var ascent = CGFloat.zero
        var descent = CGFloat.zero
        var leading = CGFloat.zero
        let width = CTLineGetTypographicBounds(ctLine, &ascent, &descent, &leading)
        self.lineWidth = width
        self.ascent = ascent
        self.descent = descent
        self.leading = leading
        
        self.bounds = CGRect(
            x: position.x,
            y: position.y - ascent,
            width: width,
            height: ascent + descent
        )
        
        self.reloadAttachments()
    }
    
    private func reloadAttachments() {
        var _attachments: [YQRichTextAttachment] = []
        var _attachmentRanges: [NSRange] = []
        var _attachmentRects: [CGRect] = []
        
        let runs: NSArray = CTLineGetGlyphRuns(ctLine)
        let runCount = runs.count
        
        for i in 0..<runCount {
            let run = runs[i] as! CTRun
            let glyphCount = CTRunGetGlyphCount(run)
            if glyphCount == 0 {
                continue
            }
            let attrs = CTRunGetAttributes(run) as! [NSAttributedString.Key : Any]
            if let attachment = attrs[.richTextAttachment] as? YQRichTextAttachment {
                var runPosition = CGPoint.zero
                CTRunGetPositions(run, CFRange(location: 0, length: 1), &runPosition)
                
                var ascent = CGFloat.zero
                var descent = CGFloat.zero
                var leading = CGFloat.zero
                let runWidth = CTRunGetTypographicBounds(run, CFRange(), &ascent, &descent, &leading)
                
                runPosition.x += position.x
                runPosition.y = position.y - runPosition.y
                let runTypoBounds = CGRect(
                    x: runPosition.x,
                    y: runPosition.y - ascent,
                    width: runWidth,
                    height: ascent + descent
                )
                
                let runRange = CTRunGetStringRange(run)
                _attachments.append(attachment)
                _attachmentRanges.append(NSRange(location: runRange.location, length: runRange.length))
                _attachmentRects.append(runTypoBounds)
            }
        }
        
        self.attachments = _attachments
        self.attachmentRanges = _attachmentRanges
        self.attachmentRects = _attachmentRects
    }
}
