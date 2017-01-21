//
//  MenuCell.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/16/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit

class MenuCell: UICollectionViewCell{
    
    override var isHighlighted: Bool {
        
        didSet{
            self.backgroundColor = isHighlighted ?  .darkGray : .white
            nameLabel.textColor = isHighlighted ? .white : .black
        }
    }
    
    let nameLabel:UILabel = {
        let label = UILabel()
        return label
    }()
    
    override init(frame: CGRect){
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupViews(){
        self.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor, constant: -16).isActive = true
        self.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor).isActive = true
        self.topAnchor.constraint(equalTo: nameLabel.topAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: nameLabel.bottomAnchor).isActive = true
    }
    
    
    
}

