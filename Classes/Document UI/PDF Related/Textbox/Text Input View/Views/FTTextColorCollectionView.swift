//
//  FTTextColorCollectionView.swift
//  Noteshelf
//
//  Created by Mahesh on 01/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

struct FTTextColorsConfig {
    static let horzSectionInset: CGFloat = 16.0
    static let lineSpacing: CGFloat = 12.0
    static let colorViewSize: CGFloat = 36.0
    static let borderWidth: CGFloat = 1.0
}

var textColors = ["#000000", "#858585", "#C2C2C2", "#FEFFFE", "#2C0977", "#0061FD", "#7A219E", "#FF4015", "#B51A00", ""]

protocol FTTextColorCollectionViewDelegate: NSObjectProtocol {
    func didSelectTextColor(_ colorStr: String)
}

class FTTextColorCollectionView: UICollectionView {

    var lastSelectedIndex = 0
    var selectedColor: String? = "#000000"
    weak var textColorDelegate: FTTextColorCollectionViewDelegate?
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        config()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        config()
    }
    
    func config() {
        self.register(UINib(nibName: "FTColorCell", bundle: nil), forCellWithReuseIdentifier: "FTColorCell")
        self.delegate = self
        self.dataSource = self
        self.backgroundColor = .clear
        self.selectItem(at: IndexPath(item: 0, section: 0), animated: true, scrollPosition: [])
    }
    
    func updateSelectedColor() {
        let indexPath = IndexPath(row: lastSelectedIndex, section: 0)
        if let cell = self.cellForItem(at: indexPath) {
            cell.isSelected = false
        }
        
        if let color = selectedColor {
            if let index = textColors.firstIndex(where: {$0.replacingOccurrences(of: "#", with: "") == color.replacingOccurrences(of: "#", with: "")}) {
                lastSelectedIndex = index
                if let cell = self.cellForItem(at: IndexPath(row: lastSelectedIndex, section: 0)) as? FTColorCell {
                    cell.isSelected = true
                }
                if let cell = self.cellForItem(at: IndexPath(row: textColors.count - 1, section: 0)) as? FTColorCell {
                    cell.colorWellBtn?.selectedColor = nil
                }
            } else {
                if let cell = self.cellForItem(at: IndexPath(row: textColors.count - 1, section: 0)) as? FTColorCell {
                    lastSelectedIndex = textColors.count - 1
                    cell.isSelected = true
                    cell.updateCustomColorCellUI(color)
                }
            }
        }
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension FTTextColorCollectionView: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return textColors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTColorCell", for: indexPath) as? FTColorCell else {
            return UICollectionViewCell()
        }
        cell.delegate = self
        let color = textColors[indexPath.row]
        if color == "" {
            cell.updateCustomColorCellUI(color)
        } else {
            cell.updatebackgroundColor(colorStr: color)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let color = textColors[indexPath.row]
        self.textColorDelegate?.didSelectTextColor(color)
    }
}

extension FTTextColorCollectionView: FTColorWellDelegate {
    func didSelectColor(_ color: UIColor?) {
        if let _color = color {
            self.textColorDelegate?.didSelectTextColor(_color.hexStringFromColor())
        }
    }
}

class FTTextColorsFlowLayout: UICollectionViewFlowLayout {
    override func prepare() {
        super.prepare()
        self.scrollDirection = .vertical
        self.itemSize = CGSize(width: FTTextColorsConfig.colorViewSize, height: FTTextColorsConfig.colorViewSize)
        self.setupLayout()
    }

    private func setupLayout() {
        guard let collectionView = collectionView else { return }
        let size = collectionView.bounds

        let textColorsCount = textColors.count
        let singleLineItemsWidth: CGFloat = CGFloat(textColorsCount/2) * (FTTextColorsConfig.colorViewSize)
        let vertSectionInset: CGFloat = size.height - (2 * FTTextColorsConfig.colorViewSize) - FTTextColorsConfig.lineSpacing
        let itemSpacing: CGFloat = (size.width - singleLineItemsWidth)/CGFloat(textColorsCount/2 - 1) - (2 * CGFloat(textColorsCount/2) * FTTextColorsConfig.borderWidth)
        self.sectionInset = UIEdgeInsets(top: vertSectionInset/2, left: FTTextColorsConfig.horzSectionInset, bottom: vertSectionInset/2, right: FTTextColorsConfig.horzSectionInset)
        self.minimumLineSpacing = FTTextColorsConfig.lineSpacing
        self.minimumInteritemSpacing = itemSpacing
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}
