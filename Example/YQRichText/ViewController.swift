//
//  ViewController.swift
//  YQRichText
//
//  Created by YQChan on 08/30/2022.
//  Copyright (c) 2022 YQChan. All rights reserved.
//

import UIKit
import YQRichText

class ViewController: UIViewController {

    @IBOutlet weak var contentLabel: YQRichTextLabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let font = UIFont.systemFont(ofSize: 20)
        let color = UIColor.blue
        let moreLabel: YQRichTextLabel = {
            let label = YQRichTextLabel()
            let link = YQRichTextLink { [weak self] text in
                self?.contentLabel.numberOfLines = 0
            }
            label.attributedText = NSAttributedString(
                string: " More",
                attributes: [
                    .foregroundColor : color,
                    .richTextLink : link,
                    .font : font
                ]
            )
            label.sizeToFit()
            return label
        }()
        
        contentLabel.numberOfLines = 2
        contentLabel.font = font
        contentLabel.textColor = .darkGray
        
        let token = NSMutableAttributedString(
            string: "...",
            attributes: [.font : font, .foregroundColor : UIColor.darkGray]
        )
        token.append(
            YQRichTextAttributedStringWrapper.attachmentString(moreLabel, alignTo: font)
        )
        contentLabel.truncationToken = token
        
        let topicParser = YQRichTextTopicParser(color: color)
        let urlParser = YQRichTextURLParser(color: color)
        var mapper = [String : UIImage]()
        mapper["[laugh]"] = UIImage(named: "emoji_00")
        let emojiParser = YQRichTextEmotionParser(mapper: mapper)
        let parser = YQRichTextContainerParser(parsers: topicParser, urlParser, emojiParser)
        contentLabel.textParser = parser
        
        contentLabel.text = content
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

private let content = """
#HTTP 定义了与服务器交互的不同方法，最基本的方法有4种，分别是GET，POST，PUT，DELETE。URL全称是资源描述符，我们可以这样认为：一个URL地址，它用于描述一个网络上的资源，而 HTTP 中的GET，POST，PUT，DELETE就对应着对这个资源的查，增，改，删4个操作。[laugh]

GET 用于信息获取，而且应该是安全的 和 幂等的。

所谓安全的意味着该操作用于获取信息而非修改信息。换句话说，GET 请求一般不应产生副作用。就是说，它仅仅是获取资源信息，就像数据库查询一样，不会修改，增加数据，不会影响资源的状态。

幂等的意味着对同一 URL 的多个请求应该返回同样的结果。

https://github.com
"""
