//
//  FTBasicTemplatesCategoryModel.swift
//  FTNewNotebook
//
//  Created by Ramakrishna on 02/03/23.
//

import Foundation

public struct FTBasicTemplateCategoryModel {
    public let categoryData: [FTThemeable]
    public let categoryTitle: String
    public init(categoryData: [FTThemeable], categoryTitle: String) {
        self.categoryData = categoryData
        self.categoryTitle = categoryTitle
    }
}
