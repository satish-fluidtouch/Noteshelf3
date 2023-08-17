//
//  FTThemesTableViewCell.swift
//  Noteshelf
//
//  Created by Matra on 16/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//


import UIKit
import FTCommon

class FTThemesTableViewCell: FTSettingsBaseTableViewCell {
    @IBOutlet weak var themeLabel: FTSettingsLabel!
    @IBOutlet weak var collectionView: UICollectionView!
    fileprivate var themes = [FTShelfThemeStyle]()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.themeLabel.text = NSLocalizedString("SettingColorScheme", comment: "Color Scheme");
        self.themeLabel.addCharacterSpacing(kernValue: -0.41)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.collectionView.collectionViewLayout.invalidateLayout()
        self.refreshAutoThemeView()
    }

    func refreshAutoThemeView() {
        let indexPath = IndexPath(row: 0, section: 0)
        self.collectionView.reloadItems(at: [indexPath])
    }
    
    func populateCell(_ themes: [FTShelfThemeStyle]) {
        self.themes = themes
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }
}

extension FTThemesTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.getCellSize()
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if(self.traitCollection.horizontalSizeClass == .regular) {
            return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        } else {
            return UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        }
    }
    func getCellSize() -> CGSize {

        let leftPadging: CGFloat = 24
        let interItemSpcing: CGFloat = 12
        var minimumCellWidth: CGFloat = 82.0
        var cellSize = CGSize(width: minimumCellWidth, height: 120)
        let collectionWidth = self.frame.width

        if !(self.isRegularClass()) {
            minimumCellWidth = 50
            var totalOcuupiedWidth = ((minimumCellWidth * 4) + ((4 - 1) * interItemSpcing) + (2 * leftPadging))
            if collectionWidth - totalOcuupiedWidth > 0 {
                cellSize.width = (collectionWidth - (2 * leftPadging) - ((4 - 1) * interItemSpcing)) / 4
            } else {
                totalOcuupiedWidth = ((minimumCellWidth * 3) + ((3 - 1) * interItemSpcing) + (2 * leftPadging))
                if collectionWidth - totalOcuupiedWidth > 0 {
                    cellSize.width = (collectionWidth - (2 * leftPadging) - ((3 - 1) * interItemSpcing)) / 3
                } else {
                    cellSize.width = (collectionWidth - (2 * leftPadging) - interItemSpcing) / 2
                }
            }
        }
        return cellSize
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.themes.count;
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let theme = self.themes[indexPath.row];
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FTThemeColorCollectionViewCell.className, for: indexPath) as? FTThemeColorCollectionViewCell else {
            fatalError("Programmer error, Couldnot find FTThemeColorCollectionViewCell")
        }
        cell.configureShelfThemeView(theme: theme)
        if let color = theme.shelfSwatchColor {
            cell.shelfThemeView.backgroundColor = theme.swatchColor
            cell.imageView.backgroundColor = color
            cell.imageView.image = nil
        }
        let selected = theme.isCurrent()
        cell.isItemSelected = selected
        return cell
    }

    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let theme = self.themes[indexPath.row];

            if let collectionViewCells = collectionView.visibleCells as? [FTThemeColorCollectionViewCell] {
                collectionViewCells.forEach({ item in
                    item.isItemSelected = false
                    item.imageView.accessibilityTraits = UIAccessibilityTraits.none
                });
            }

        if let cell = collectionView.cellForItem(at: indexPath) as? FTThemeColorCollectionViewCell {
            cell.isItemSelected = true
            cell.imageView.accessibilityTraits = UIAccessibilityTraits.selected

            let spinner = UIActivityIndicatorView(style: .gray)
            cell.addSubview(spinner)

            spinner.frame = CGRect(x: (cell.bounds.width - spinner.frame.width) / 2, y: (cell.bounds.height - spinner.frame.height) / 2, width: spinner.frame.width, height: spinner.frame.height)

            spinner.startAnimating()
            DispatchQueue.main.async {
                theme.setAsDefault();
                spinner.removeFromSuperview();
                track("Shelf_Settings_Appearance_Selection", params: ["appearance":"\(theme.themeColor.hexString)"], screenName: FTScreenNames.shelfSettings)
            }
        }
    }
}
