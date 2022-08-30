//
//  YQRichTextLink.swift
//  YQRichText
//
//  Created by CYQ on 2022/8/30.
//

import UIKit

public class YQRichTextLink {
    
    public let tapActionBlock: (String) -> Void
    
    public init(_ tapActionBlock: @escaping (String) -> Void) {
        self.tapActionBlock = tapActionBlock
    }
}
