//
//  MessagesCollectionViewCell.swift
//  MonEx
//
//  Created by Carlos De la mora on 2/13/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit
import CoreGraphics

class MessagesCollectionViewCell: UICollectionViewCell {
    
    let textView: UITextView = {
        let textView = UITextView()
        textView.text = "Sample Text"
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.isScrollEnabled = false
        textView.isEditable = false
        return textView
    }()
    
    let bubbleView: UIView = {
       let view = UIView()
       view.backgroundColor = UIColor(colorLiteralRed: 0, green: 137/255, blue: 249/255, alpha: 1)
       view.translatesAutoresizingMaskIntoConstraints = false
       view.layer.cornerRadius = 16
       view.clipsToBounds = true
       return view
    }()
    
    var bubleWidthAnchor: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(bubbleView)
        bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -16).isActive = true
        bubbleView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        bubbleView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        bubleWidthAnchor = bubbleView.widthAnchor.constraint(equalToConstant: 200)
        bubleWidthAnchor?.isActive = true
        
        addSubview(textView)
        textView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 8).isActive = true
        textView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        textView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        textView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init aDecoder has not been implemented")
    }
    
}
