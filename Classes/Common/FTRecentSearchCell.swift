//
//  FTRecentSearchCell.swift
//  Noteshelf
//
//  Created by Narayana on 08/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

let kRecentSearchCell = "RecentSearchCell"

class FTRecentSearchCell: UITableViewCell {
    private func config() -> UIListContentConfiguration {
        var contentConfig = UIListContentConfiguration.cell()
        contentConfig.textProperties.color = UIColor.headerColor
        contentConfig.textProperties.font = UIFont.appFont(for: .regular, with: 17.0)
        return contentConfig
    }

    func configureCell(with items: [FTRecentSearchedItem]) {
        self.separatorInset = .zero
        self.backgroundColor = UIColor.clear
        self.selectionStyle = .none
        var stringToShow = ""
        for (index, eachItem) in  items.enumerated() {
            if index == 0 {
                stringToShow = eachItem.name
            } else {
                let attrText = (index == (items.count - 1) ) ? " and" : " ,"
                stringToShow.append(attrText)
                stringToShow.append((" \(eachItem.name)"))
            }
        }
        var config = self.config()
        config.text = stringToShow
        self.contentConfiguration = config
    }
}
