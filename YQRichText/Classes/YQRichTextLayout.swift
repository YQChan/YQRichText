//
//  YQRichTextLayout.swift
//  YQRichText
//
//  Created by CYQ on 2022/8/30.
//

import UIKit

private let defaultTruncationToken = "..."

class YQRichTextLayout {
    
    var truncationToken: NSAttributedString?
    
    var numberOfLines = 1
    
    private(set) var textBoundingRect = CGRect.zero
    private(set) var textBoundingSize = CGSize.zero
    
    private(set) var visibleRange = NSRange()
    
    private var lines: [YQRichTextLine] = []
    
    private var drawAttachmentViews = [UIView]()
    
    func layout(text: NSAttributedString, in rect: CGRect) {
        let _rect = rect.applying(CGAffineTransform(scaleX: 1, y: -1))
        
        let path = CGMutablePath()
        path.addRect(_rect)
        
        let ctSetter = CTFramesetterCreateWithAttributedString(text)
        let ctFrame = CTFramesetterCreateFrame(ctSetter, CFRange(location: 0, length: text.length), path, nil)
        let ctLines: NSArray = CTFrameGetLines(ctFrame)
        let lineCount = numberOfLines == 0 ? ctLines.count : min(numberOfLines, ctLines.count)
        var lineOrigins = [CGPoint](repeating: .zero, count: lineCount)
        CTFrameGetLineOrigins(ctFrame, CFRange(location: 0, length: lineCount), &lineOrigins)
        
        var _lines: [YQRichTextLine] = []
        var _textBoundingRect = CGRect.zero
        
        for i in 0..<lineCount {
            let ctLine = ctLines[i] as! CTLine
            
            // CoreText坐标轴
            let ctLineOrigin = lineOrigins[i]
            
            // UIKit坐标轴
            let position = CGPoint(x: ctLineOrigin.x, y: _rect.height - ctLineOrigin.y)
            
            var textLine = YQRichTextLine(ctLine: ctLine, position: position)
            // 计算BoundingRect
            _textBoundingRect = i == 0 ? textLine.bounds : _textBoundingRect.union(textLine.bounds)
            
            if i == lineCount - 1 {
                let range = textLine.range
                // 判断是否需要截断
                if range.location + range.length < text.length {
                    // 创建 truncated line
                    let _truncationToken: NSAttributedString
                    if let token = self.truncationToken {
                        _truncationToken = token
                    } else {
                        let ctRuns: NSArray = CTLineGetGlyphRuns(ctLine)
                        let runCount = ctRuns.count
                        var attrs = [NSAttributedString.Key : Any]()
                        if runCount > 0 {
                            let ctRun = ctRuns[runCount - 1] as! CTRun
                            attrs = CTRunGetAttributes(ctRun) as! [NSAttributedString.Key : Any]
                        }
                        _truncationToken = NSAttributedString(string: defaultTruncationToken, attributes: attrs)
                    }
                    let truncationTokenLine = CTLineCreateWithAttributedString(_truncationToken)
                    
                    let lastLineText = NSMutableAttributedString(attributedString: text.attributedSubstring(from: range))
                    lastLineText.append(_truncationToken)
                    let ctLastLineExtend = CTLineCreateWithAttributedString(lastLineText)
                    if let ctTruncatedLine = CTLineCreateTruncatedLine(ctLastLineExtend, _rect.size.width, .end, truncationTokenLine) {
                        textLine = YQRichTextLine(ctLine: ctTruncatedLine, position: position)
                    }
                }
            }
            
            _lines.append(textLine)
        }
        self.lines = _lines
        self.textBoundingRect = _textBoundingRect
        self.textBoundingSize = CGSize(
            width: _textBoundingRect.width,
            height: ceil(_textBoundingRect.height + _textBoundingRect.origin.y)
        )
        let ctRange = CTFrameGetVisibleStringRange(ctFrame)
        self.visibleRange = NSRange(location: ctRange.location, length: ctRange.length)
    }
    
    // 绘制文本
    func drawText(in context: CGContext, size: CGSize) {
        context.saveGState()
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)
        
        for line in lines {
            let ctRuns: NSArray = CTLineGetGlyphRuns(line.ctLine)
            let position = CGPoint(x: line.position.x, y: size.height - line.position.y)
            for j in 0..<ctRuns.count {
                let ctRun = ctRuns[j] as! CTRun
                context.textMatrix = .identity
                context.textPosition = position
                CTRunDraw(ctRun, context, CFRange())
            }
        }
        context.restoreGState()
    }
    
    // 绘制Attachment
    func drawAttachment(in context: CGContext, view: UIView) {
        var views = [UIView]()
        for line in lines {
            for (i, a) in line.attachments.enumerated() {
                let rect = line.attachmentRects[i]
                switch a {
                case let viewItem as YQRichTextViewAttachment:
                    let _view = viewItem.view
                    _view.frame = rect
                    view.addSubview(_view)
                    views.append(_view)
                case let imageItem as YQRichTextImageAttachment:
                    if let image = imageItem.image.cgImage {
                        context.saveGState()
                        context.translateBy(x: 0, y: rect.maxY + rect.minY)
                        context.scaleBy(x: 1, y: -1)
                        context.draw(image, in: rect)
                        context.restoreGState()
                    }
                default:
                    continue
                }
            }
        }
        self.drawAttachmentViews = views
    }
    
    func removeAttachments() {
        while let view = self.drawAttachmentViews.popLast() {
            view.removeFromSuperview()
        }
    }
    
    func textIndex(at point: CGPoint) -> Int? {
        for line in lines {
            let bounds = line.bounds
            if bounds.contains(point) {
                var index = CTLineGetStringIndexForPosition(line.ctLine, CGPoint(x: point.x - bounds.minX, y: point.y - bounds.minY))
                if index == visibleRange.location + visibleRange.length {
                    index -= 1
                } else if index != visibleRange.location {
                    var glyphStart: CGFloat = 0.0
                    CTLineGetOffsetForStringIndex(line.ctLine, index, &glyphStart)
                    if point.x < glyphStart {
                        index -= 1
                    }
                }
                
                if index >= visibleRange.location && index < visibleRange.location + visibleRange.length {
                    return index
                }
                
                break
            }
        }
        return nil
    }
}
