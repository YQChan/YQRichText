//
//  YQRichTextLabel.swift
//  YQRichText
//
//  Created by CYQ on 2022/8/30.
//

import UIKit

private let maxContentSize = CGSize(width: 0x100000, height: 0x100000)

open class YQRichTextLabel: UIView {
    
    public var text: String? {
        get {
            return self.drawText?.string
        }
        set {
            if let string = newValue, string.isEmpty == false {
                var attributes: [NSAttributedString.Key : Any] = [
                    .font : self.font,
                    .foregroundColor : self.textColor
                ]
                if self.lineHeight.isZero == false {
                    let style = NSMutableParagraphStyle()
                    style.minimumLineHeight = self.lineHeight
                    attributes[.paragraphStyle] = style
                }
                let _text = NSMutableAttributedString(
                    string: string,
                    attributes: attributes
                )
                self.textParser?.parse(text: _text)
                self.drawText = _text
            } else {
                self.drawText = nil
            }
        }
    }
    
    public var attributedText: NSAttributedString? {
        get {
            return self.drawText
        }
        set {
            if let string = newValue, string.string.isEmpty == false {
                let _text = NSMutableAttributedString(attributedString: string)
                self.textParser?.parse(text: _text)
                self.drawText = _text
            } else {
                self.drawText = nil
            }
        }
    }
    
    public var numberOfLines = 1 {
        didSet {
            self.textLayout.numberOfLines = numberOfLines
            self.reload()
            self.invalidateIntrinsicContentSize()
        }
    }
    
    public var font = UIFont.systemFont(ofSize: 17) {
        didSet {
            self.drawText?.yq.font = font
            self.reload()
            self.invalidateIntrinsicContentSize()
        }
    }
    
    public var textColor = UIColor.black {
        didSet {
            self.drawText?.yq.textColor = textColor
            self.reload()
        }
    }
    
    public var truncationToken: NSAttributedString? {
        didSet {
            self.reload()
            self.invalidateIntrinsicContentSize()
            self.textLayout.truncationToken = truncationToken
        }
    }
    
    public var textParser: YQRichTextParser? {
        didSet {
            if let text = self.drawText {
                textParser?.parse(text: text)
            }
            self.reload()
            self.invalidateIntrinsicContentSize()
        }
    }
    
    public var preferredMaxLayoutWidth: CGFloat = .zero {
        didSet {
            if oldValue != preferredMaxLayoutWidth {
                self.invalidateIntrinsicContentSize()
            }
        }
    }
    
    public var lineHeight: CGFloat = .zero {
        didSet {
            if oldValue != lineHeight {
                let style = NSMutableParagraphStyle()
                style.minimumLineHeight = lineHeight
                self.drawText?.yq.addAttribute(.paragraphStyle, value: style)
                self.reload()
                self.invalidateIntrinsicContentSize()
            }
        }
    }
    
    func append(_ string: NSAttributedString) {
        self.drawText?.append(string)
    }
    
    private var drawText: NSMutableAttributedString? {
        didSet {
            self.reload()
            self.invalidateIntrinsicContentSize()
        }
    }
    
    private lazy var textLayout = YQRichTextLayout()
    
    private var textLink: YQRichTextLink?
    
    private var textLinkRange = NSRange()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }
    
    private func commonInit() {
        self.isUserInteractionEnabled = true
        self.backgroundColor = .clear
    }
    
    private func reload() {
        self.setNeedsDisplay()
    }
    
    open override func draw(_ rect: CGRect) {
        textLayout.removeAttachments()
        
        guard let _text = self.drawText else {
            return
        }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        textLayout.layout(text: _text, in: bounds)
        textLayout.drawText(in: context, size: bounds.size)
        textLayout.drawAttachment(in: context, view: self)
    }
    
    open override var intrinsicContentSize: CGSize {
        return sizeThatFits(bounds.size)
    }
    
    open override var frame: CGRect {
        didSet {
            if oldValue.size != frame.size {
                self.reload()
            }
        }
    }
    
    open override var bounds: CGRect {
        didSet {
            if oldValue.size != bounds.size {
                self.reload()
                self.invalidateIntrinsicContentSize()
            }
        }
    }
    
    open override func sizeToFit() {
        self.frame.size = intrinsicContentSize
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let _text = self.drawText, _text.string.isEmpty == false else { return .zero }
        var rect = CGRect(x: 0, y: 0, width: size.width, height: maxContentSize.height)
        if rect.width.isZero {
            rect.size.width = self.preferredMaxLayoutWidth.isZero ? maxContentSize.width : self.preferredMaxLayoutWidth
        }
        textLayout.layout(text: _text, in: rect)
        return textLayout.textBoundingSize
    }
    
    // MARK: - 点击手势处理
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer {
            if self.textLink == nil {
                super.touchesBegan(touches, with: event)
            }
        }
        guard let _text = self.drawText, _text.string.isEmpty == false else {
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
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.textLink == nil {
            super.touchesEnded(touches, with: event)
            return
        }
        var string = ""
        if let _text = self.drawText {
            if self.textLinkRange.length > 0 && self.textLinkRange.location + self.textLinkRange.length <= _text.length {
                string = (_text.string as NSString).substring(with: self.textLinkRange)
            }
        }
        self.textLink?.tapActionBlock(string)
        self.textLink = nil
        self.textLinkRange = NSRange()
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.textLink == nil {
            super.touchesCancelled(touches, with: event)
            return
        }
        self.textLink = nil
        self.textLinkRange = NSRange()
    }
}
