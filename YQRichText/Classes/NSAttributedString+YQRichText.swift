//
//  NSAttributedString+YQRichText.swift
//  YQRichText
//
//  Created by CYQ on 2022/8/30.
//

import UIKit

public protocol YQRichTextAttributedString {}

extension YQRichTextAttributedString where Self: NSAttributedString {
    
    public var yq: YQRichTextAttributedStringWrapper<Self> {
        get {
            return YQRichTextAttributedStringWrapper(string: self)
        }
        set {
            
        }
    }
}

extension NSAttributedString: YQRichTextAttributedString {
    
}

public struct YQRichTextAttributedStringWrapper<AttributedString: NSAttributedString> {
    
    public var textRange: NSRange {
        return NSRange(location: 0, length: string.length)
    }
    
    public var textColor: UIColor? {
        return attribute(.foregroundColor, at: 0)
    }
    
    public var font: UIFont? {
        return attribute(.font, at: 0)
    }
    
    let string: AttributedString
    
    init(string: AttributedString) {
        self.string = string
    }
    
    public func attribute<T>(_ name: NSAttributedString.Key, at index: Int) -> T? {
        return string.attribute(name, at: index, effectiveRange: nil) as? T
    }
    
    public static func attachmentString(_ image: UIImage, alignTo font: UIFont) -> NSAttributedString {
        return self.attachmentString(YQRichTextImageAttachment(image), alignTo: font)
    }
    
    public static func attachmentString(_ view: UIView, alignTo font: UIFont) -> NSAttributedString {
        return self.attachmentString(YQRichTextViewAttachment(view), alignTo: font)
    }
    
    static func attachmentString(_ attachment: YQRichTextAttachment, alignTo font: UIFont) -> NSAttributedString {
        let attachmentToken = "\u{FFFC}"
        let attr = NSMutableAttributedString(string: attachmentToken)
        attr.addAttribute(.richTextAttachment, value: attachment, range: NSRange(location: 0, length: attr.length))
        let delegate = YQRichTextRunDelegate(
            ascent: attachment.size.height + font.descender,
            descent: -font.descender,
            width: attachment.size.width
        )
        if let runDelegate = delegate.runDelegate {
            attr.addAttribute(
                NSAttributedString.Key(kCTRunDelegateAttributeName as String),
                value: runDelegate,
                range: NSRange(location: 0, length: attr.length)
            )
        }
        return attr
    }
}

extension YQRichTextAttributedStringWrapper where AttributedString: NSMutableAttributedString {
    
    public var textColor: UIColor? {
        get {
            return attribute(.foregroundColor, at: 0)
        }
        set {
            addAttribute(.foregroundColor, value: newValue)
        }
    }
    
    public var font: UIFont? {
        get {
            return attribute(.font, at: 0)
        }
        set {
            addAttribute(.font, value: newValue)
        }
    }
    
    public func addAttribute(_ name: NSAttributedString.Key, value: Any?, range: NSRange? = nil) {
        let _range = range ?? textRange
        if let _value = value {
            string.addAttribute(name, value: _value, range: _range)
        } else {
            string.removeAttribute(name, range: _range)
        }
    }
}
