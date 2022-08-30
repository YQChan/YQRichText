//
//  YQRichTextParser.swift
//  YQRichText
//
//  Created by CYQ on 2022/8/30.
//

import UIKit

public protocol YQRichTextParser {
    func parse(text: NSMutableAttributedString)
}

public class YQRichTextContainerParser: YQRichTextParser {
    
    private let parsers: [YQRichTextParser]
    
    public init(parsers: [YQRichTextParser]) {
        self.parsers = parsers
    }
    
    public convenience init(parsers: YQRichTextParser?...) {
        self.init(parsers: parsers.compactMap { $0 })
    }
    
    public func parse(text: NSMutableAttributedString) {
        for parse in self.parsers {
            parse.parse(text: text)
        }
    }
}

open class YQRichTextExpressionParser: YQRichTextParser {
    
    public let expression: NSRegularExpression
    
    public init?(pattern: String) {
        do {
            self.expression = try NSRegularExpression(
                pattern: pattern,
                options: .caseInsensitive
            )
        } catch {
            print(error)
            return nil
        }
    }
    
    open func parse(text: NSMutableAttributedString) {
        
    }
}

public class YQRichTextEmotionParser: YQRichTextExpressionParser {
    
    private let mapper: [String : UIImage]
    
    public init?(mapper: [String : UIImage]) {
        self.mapper = mapper
        super.init(pattern: "\\[[a-zA-Z0-9\\u4e00-\\u9fa5]+\\]")
    }
    
    public override func parse(text: NSMutableAttributedString) {
        let results = self.expression.matches(
            in: text.string,
            range: text.yq.textRange
        )
        var cutLength = 0
        for result in results {
            var oneRange = result.range
            if oneRange.length == 0 {
                continue
            }
            oneRange.location -= cutLength
            let subStr = (text.string as NSString).substring(with: oneRange)
            guard let image = self.mapper[subStr] else {
                continue
            }
            let font = text.yq.font ?? UIFont.systemFont(ofSize: 17)
            let attr = YQRichTextAttributedStringWrapper.attachmentString(image, alignTo: font)
            text.replaceCharacters(in: oneRange, with: attr)
            cutLength += oneRange.length - 1
        }
    }
}

open class YQRichTextLinkParser: YQRichTextExpressionParser {
    
    private let link: YQRichTextLink?
    
    private let color: UIColor
    
    public init?(color: UIColor, link: YQRichTextLink? = nil, pattern: String) {
        self.link = link
        self.color = color
        super.init(pattern: pattern)
    }
    
    public override func parse(text: NSMutableAttributedString) {
        let results = self.expression.matches(
            in: text.string,
            range: text.yq.textRange
        )
        var attributes: [NSAttributedString.Key : Any] = [:]
        attributes[.foregroundColor] = color
        attributes[.richTextLink] = link
        for result in results {
            text.addAttributes(
                attributes,
                range: result.range
            )
        }
    }
}

public class YQRichTextURLParser: YQRichTextLinkParser {
    
    public init?(color: UIColor, link: YQRichTextLink? = nil) {
        super.init(
            color: color,
            link: link,
            pattern: "((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)"
        )
    }
}

public class YQRichTextTopicParser: YQRichTextLinkParser {
    
    public init?(color: UIColor, link: YQRichTextLink? = nil) {
        super.init(
            color: color,
            link: link,
            pattern: "#[^#\\s]+"
        )
    }
}
