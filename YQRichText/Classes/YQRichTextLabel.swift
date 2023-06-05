//
//  YQRichTextLabel.swift
//  YQRichText
//
//  Created by CYQ on 2022/8/30.
//

import UIKit

public class YQRichTextLabel: UILabel {
    
    public override var text: String? {
        didSet {
            self.updateTextParser()
        }
    }
    
    public override var attributedText: NSAttributedString? {
        didSet {
            self.updateTextParser()
        }
    }
    
    public override var numberOfLines: Int {
        didSet {
            self.textLayout.numberOfLines = numberOfLines
        }
    }
    
    public override var lineBreakMode: NSLineBreakMode {
        get {
            return _lineBreakMode
        }
        set {
            _lineBreakMode = newValue
        }
    }
    
    private var _lineBreakMode: NSLineBreakMode = .byWordWrapping {
        didSet {
            switch _lineBreakMode {
            case .byWordWrapping, .byCharWrapping, .byClipping:
                super.lineBreakMode = _lineBreakMode
            case .byTruncatingHead, .byTruncatingMiddle, .byTruncatingTail:
                super.lineBreakMode = .byWordWrapping
            @unknown default:
                super.lineBreakMode = .byWordWrapping
            }
        }
    }
    
    public var truncationToken: NSAttributedString? {
        didSet {
            self.setNeedsDisplay()
            self.invalidateIntrinsicContentSize()
            self.textLayout.truncationToken = truncationToken
        }
    }
    
    public var textParser: YQRichTextParser? {
        didSet {
            self.updateTextParser()
        }
    }
    
    private lazy var textLayout = YQRichTextLayout()
    
    private var textLink: YQRichTextLink?
    
    private var textLinkRange = NSRange()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    private func setup() {
        self.isUserInteractionEnabled = true
        super.lineBreakMode = .byWordWrapping
    }
    
    private func updateTextParser() {
        guard let _text = self.attributedText, _text.string.isEmpty == false, let parser = self.textParser else {
            return
        }
        let newText = NSMutableAttributedString(attributedString: _text)
        parser.parse(text: newText)
        super.attributedText = newText
    }
    
    public override func draw(_ rect: CGRect) {
        textLayout.removeAttachments()
        
        guard let _text = self.attributedText else {
            return
        }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        textLayout.layout(text: _text, in: bounds)
        textLayout.drawText(in: context, size: bounds.size)
        textLayout.drawAttachment(in: context, view: self)
    }
    
    public override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        guard let _text = self.attributedText, _text.string.isEmpty == false else {
            return super.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
        }
        var rect = bounds
        let maxContentSize = UIView.layoutFittingExpandedSize
        rect.size.width = min(maxContentSize.width, rect.width)
        rect.size.height = min(maxContentSize.height, rect.height)
        textLayout.layout(text: _text, in: rect)
        var textRect = CGRect.zero
        textRect.size = textLayout.textBoundingSize
        return textRect
    }
    
    // MARK: - 点击手势处理
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer {
            if self.textLink == nil {
                super.touchesBegan(touches, with: event)
            }
        }
        guard let _text = self.attributedText, _text.string.isEmpty == false else {
            return
        }
        guard let touch = touches.first else { return }
        if touch.view == self {
            let point = touch.location(in: touch.view)
            if let index = textLayout.textIndex(at: point) {
                let range = _text.yq.textRange
                self.textLink = _text.attribute(
                    .richTextLink,
                    at: index,
                    longestEffectiveRange: &self.textLinkRange,
                    in: range
                ) as? YQRichTextLink
            }
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.textLink == nil {
            super.touchesEnded(touches, with: event)
            return
        }
        var string = ""
        if let _text = self.attributedText {
            if self.textLinkRange.length > 0 && self.textLinkRange.location + self.textLinkRange.length <= _text.length {
                string = (_text.string as NSString).substring(with: self.textLinkRange)
            }
        }
        self.textLink?.tapActionBlock(string)
        self.textLink = nil
        self.textLinkRange = NSRange()
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.textLink == nil {
            super.touchesCancelled(touches, with: event)
            return
        }
        self.textLink = nil
        self.textLinkRange = NSRange()
    }
}
