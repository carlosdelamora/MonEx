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
       view.backgroundColor = Constants.color.messagesBlue
       view.translatesAutoresizingMaskIntoConstraints = false
       view.layer.cornerRadius = 16
       view.clipsToBounds = true
       return view
    }()
    
    let profileView: UIImageView = {
       let imageView = UIImageView()
       imageView.image = UIImage(named: "photoPlaceholder")
       imageView.layer.cornerRadius = imageView.frame.width/2
       imageView.clipsToBounds = true
       imageView.contentMode = .scaleAspectFit
       imageView.translatesAutoresizingMaskIntoConstraints = false
       return imageView
    }()
    
    var bubbleWidthAnchor: NSLayoutConstraint?
    var bubbleViewRightAnchor: NSLayoutConstraint?
    var bubbleViewLeftAnchor: NSLayoutConstraint?
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(profileView)
        profileView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        profileView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        profileView.heightAnchor.constraint(equalToConstant: 32).isActive = true 
        
        addSubview(bubbleView)
        bubbleViewRightAnchor = bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -16)
        bubbleViewRightAnchor?.isActive = true
        bubbleView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        bubbleView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        bubbleWidthAnchor = bubbleView.widthAnchor.constraint(equalToConstant: 200)
        bubbleWidthAnchor?.isActive = true
        
        bubbleViewLeftAnchor = bubbleView.leftAnchor.constraint(equalTo: profileView.rightAnchor, constant: 8)
        //bubbleViewLeftAnchor.isActive = false by default 
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
