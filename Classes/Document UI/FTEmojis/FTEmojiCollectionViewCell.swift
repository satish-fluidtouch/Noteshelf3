//
//  FTEmojiCollectionViewCell.swift
//  FTAddOperations
//
//  Created by Siva on 10/06/20.
//  Copyright © 2020 Siva. All rights reserved.
//

import Foundation

final class FTEmojiCollectionViewCell1: UICollectionViewCell {

    var emojisItem: FTEmojisItem? {
        didSet {
            label.text = emojisItem?.emojiSymbol
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: 32.0, height: 32.0)
    }

    private lazy var label: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.font = UIFont.systemFont(ofSize: 32)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private func setup() {
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }
    
}
