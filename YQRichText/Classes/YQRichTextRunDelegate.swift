//
//  YQRichTextRunDelegate.swift
//  YQRichText
//
//  Created by CYQ on 2022/8/30.
//

import UIKit

class YQRichTextRunDelegate {
    
    private struct Config {
        let ascent: CGFloat
        let descent: CGFloat
        let width: CGFloat
    }
    
    private let config: Config
    
    init(ascent: CGFloat, descent: CGFloat, width: CGFloat) {
        self.config = Config(ascent: ascent, descent: descent, width: width)
    }
    
    var runDelegate: CTRunDelegate? {
        var callbacks = CTRunDelegateCallbacks(version: kCTRunDelegateVersion1) { ref in
            
        } getAscent: { ref in
            let pointer = ref.assumingMemoryBound(to: Config.self)
            return pointer.pointee.ascent
        } getDescent: { ref in
            let pointer = ref.assumingMemoryBound(to: Config.self)
            return pointer.pointee.descent
        } getWidth: { ref in
            let pointer = ref.assumingMemoryBound(to: Config.self)
            return pointer.pointee.width
        }
        let pointer = UnsafeMutablePointer<Config>.allocate(capacity: 1)
        pointer.initialize(to: self.config)
        return CTRunDelegateCreate(&callbacks, pointer)
    }
}
