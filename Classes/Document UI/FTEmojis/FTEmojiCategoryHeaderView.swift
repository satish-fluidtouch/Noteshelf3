//
//  FTEmojiCollectionHeaderView.swift
//  Noteshelf
//
//  Created by srinivas on 22/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTEmojiCategoryHeaderView: UICollectionReusableView {
    
    static let identifier = "EmojiCategoryHeaderView"
    
    private lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Recents"
        label.textAlignment = .center
        label.textColor = .label
        label.font = UIFont.appFont(for: .medium, with: 13.0)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 15)
        ])
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("")
    }
    
    func configure(name: String) {
        label.text = name
    }
        
}
