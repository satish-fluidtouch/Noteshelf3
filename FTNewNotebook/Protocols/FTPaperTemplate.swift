//
//  FTPaperTemplate.swift
//  FTNewNotebook
//
//  Created by Ramakrishna on 28/02/23.
//

import Foundation

//public protocol FTPaperTemplatesVariantsDelegate: NSObject {
//    var templateBasicColors:[FTTemplateColorModel] {get}
//    var customBasicColorHex: String {get}
//    var selectedTemplateColor: FTTemplateColorModel {get}
//    var templateLineHeights: [FTTemplateLineHeightModel] {get}
//    var selectedLineHeight: FTTemplateLineHeight {get}
//    var selectedOrientation: FTTemplateOrientation {get}
//    var templateSizes: [FTTemplateSizeModel] {get}
//    var selectedTemplateSize: FTTemplateSizeModel {get}
//
//    func saveBasicTemplateColor(_ templateColor: FTTemplateColor)
//    func saveCustomColor(colorHex: String)
//    func saveLineHeight(_ lineHeight: FTTemplateLineHeight)
//    func saveOrientation(_ orientation: FTTemplateOrientation)
//    func saveTemplateSize(templateSize: FTTemplateSize)
//}
protocol FTPaperThemeDelegate: NSObject {
    var basicTemplates: [FTBasicTemplateCategoryModel] { get }
}
