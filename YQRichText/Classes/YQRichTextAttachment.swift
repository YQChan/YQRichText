//
//  YQRichTextAttachment.swift
//  YQRichText
//
//  Created by CYQ on 2022/8/30.
//

import UIKit

class YQRichTextAttachment {
    
    let size: CGSize
    
    init(size: CGSize) {
        self.size = size
    }
}

class YQRichTextViewAttachment: YQRichTextAttachment {
    
    let view: UIView
    
    init(_ view: UIView) {
        self.view = view
        super.init(size: view.frame.size)
    }
}

class YQRichTextImageAttachment: YQRichTextAttachment {
    
    let image: UIImage
    
    init(_ image: UIImage) {
        self.image = image
        super.init(size: image.size)
    }
}

extension NSAttributedString.Key {
    
    public static let richTextLink = NSAttributedString.Key("YQRichTextLinkAttributeName")
    
    public static let richTextAttachment = NSAttributedString.Key("YQRichTextAttachmentAttributeName")
}
