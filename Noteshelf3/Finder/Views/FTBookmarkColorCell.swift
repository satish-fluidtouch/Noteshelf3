//
//  FTBookmarkColorCell.swift
//  Noteshelf3
//
//  Created by Sameer Hussain on 06/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTBookmarkColorCell: UICollectionViewCell {
    let circleView = CircleView(frame: CGRect(x: 7, y: 7, width: 30, height: 30))
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.layer.masksToBounds = true
        self.layer.cornerRadius = self.frame.size.width / 2
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.appColor(.black20).cgColor
    }
    
    override var isSelected: Bool {
        willSet {
            if newValue && selectedBackgroundView == nil {
                self.selectedBackgroundView = circleView
            }
        }
    }
    
    override func awakeFromNib() {
    }

    func configureCellWithColor(color: UIColor) {
        self.backgroundColor = color
    }
}

class CircleView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        let circleView = UIView(frame: frame)
            circleView.layer.borderColor = UIColor.white.cgColor
            circleView.layer.borderWidth = 3
            circleView.layer.cornerRadius = (circleView.frame.size.width) / 2
            circleView.layer.masksToBounds = true
            self.addSubview(circleView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
