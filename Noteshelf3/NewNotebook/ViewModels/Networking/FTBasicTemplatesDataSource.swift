//
//  File.swift
//  
//
//  Created by Narayana on 18/05/22.
//

import UIKit
import SwiftUI
import FTNewNotebook

let defaultCustomColor: Color = .black

class FTBasicTemplatesDataSource: NSObject {
    private let themeLibrary: FTThemesLibrary
    private let basicCategory: FTBasicThemeCategory
    static let shared = FTBasicTemplatesDataSource()

     override private init() {
        self.themeLibrary = FTThemesLibrary.init(libraryType: .papers)
        self.basicCategory = self.themeLibrary.getBasicPaperCategory()
    }
}

 extension FTBasicTemplatesDataSource {
     // Size data communication
     func getTemplateSizeData() -> [FTTemplateSizeModel] {
         var sizeModels = [FTTemplateSizeModel]()
         let deviceManager = FTDeviceDataManager()
         let devicesData = deviceManager.fetchDeviceData().devices
         let standardiPadDevice = deviceManager.standardiPadDevice
         let standardMobileDevice = deviceManager.standardMobileDevice

         if UIDevice.current.isMac() {
             sizeModels.append(FTTemplateSizeModel(size: standardiPadDevice.displayName, portraitSize: standardiPadDevice.dimension_port, landscapeSize: standardiPadDevice.dimension_land))
         } else {
             let defaltDevice = deviceManager.getCurrentDevice()
             sizeModels.append(FTTemplateSizeModel(size: defaltDevice.displayName, portraitSize: defaltDevice.dimension_port, landscapeSize: defaltDevice.dimension_land))
         }

         //Standard sizes(Letter/A3/A4/A5)
         for deviceData in devicesData {
             let sizeModel = FTTemplateSizeModel(size: deviceData.displayName, portraitSize: deviceData.dimension_port, landscapeSize: deviceData.dimension_land)
             sizeModels.append(sizeModel)
         }

         if UIDevice.current.isIphone() {
             sizeModels.append(FTTemplateSizeModel(size: standardiPadDevice.displayName, portraitSize: standardiPadDevice.dimension_port, landscapeSize: standardiPadDevice.dimension_land))
         } else {
             sizeModels.append(FTTemplateSizeModel(size: standardMobileDevice.displayName, portraitSize: standardMobileDevice.dimension_port, landscapeSize: standardMobileDevice.dimension_land))
         }
         return sizeModels
     }
     func getDeviceModelForIPadOrMobile(_ size: FTTemplateSize) -> FTDeviceModel{
         let deviceManager = FTDeviceDataManager()
         let deviceModel: FTDeviceModel
         if size == .iPad {
             if UIDevice.current.isIpad() {
                 deviceModel = deviceManager.getCurrentDevice()
             } else {
                 deviceModel = deviceManager.standardiPadDevice
             }
         } else { // size is mobile
             if UIDevice.current.isPhone() {
                 deviceModel = deviceManager.getCurrentDevice()
             } else {
                 deviceModel = deviceManager.standardMobileDevice
             }
         }
         return deviceModel
     }
     func saveTemplateSize(templateSize: FTTemplateSize, mode:ThemeDefaultMode = .basic) {
         var variants = self.fetchSelectedVaraintsForMode(mode)
         let deviceManager = FTDeviceDataManager()
         let devicesData = deviceManager.fetchDeviceData().devices

         if templateSize == .iPad || templateSize == .mobile {
             variants.selectedDevice = getDeviceModelForIPadOrMobile(templateSize)
         } else if let reqDeviceModel  = devicesData.first(where: {$0.displayName == templateSize}) {
             variants.selectedDevice = reqDeviceModel
         }
         self.themeLibrary.storeSelectedVariants(variants, mode: mode)
     }

     func getSavedTemplateSizeModelForMode(_ mode:ThemeDefaultMode) -> FTTemplateSizeModel {
         let variants = self.fetchSelectedVaraintsForMode(mode)
         let reqSizeModel = FTTemplateSizeModel(size: variants.selectedDevice.displayName, portraitSize: variants.selectedDevice.dimension_port, landscapeSize: variants.selectedDevice.dimension_land)
         return reqSizeModel
     }

    // Color data communication
     func getTemplateColorsDataForMode(_ mode:ThemeDefaultMode) -> [FTTemplateColorModel] {
        var colorModels = [FTTemplateColorModel]()

         if let colorData = self.basicCategory.customizations?.color_variants.first as? FTThemeColorData {
            let colors = colorData.colors
            for color in colors {
                if color.colorName == .custom {
                    let colorModel = FTTemplateColorModel(color: color.colorName, hex: getSavedTemplateColorModelForMode(mode).hex)
                    colorModels.append(colorModel)
                } else {
                    let colorModel = FTTemplateColorModel(color: color.colorName, hex: color.colorHex)
                    colorModels.append(colorModel)
                }
            }
        }
        return colorModels
    }

      func saveBasicTemplateColor(_ templateColorModel: FTTemplateColorModel,
                                  mode: ThemeDefaultMode = .basic) {
          if templateColorModel.color != .custom {
             var variants = self.fetchSelectedVaraintsForMode(mode)
             if let colorVariants = self.basicCategory.customizations?.color_variants {
                 for colorVariant in colorVariants {
                     if let themeColor = colorVariant.colors.first(where: { tempThemeColor in
                         templateColorModel.color == tempThemeColor.colorName
                     }) {
                         variants.selectedColor = themeColor
                         self.themeLibrary.storeSelectedVariants(variants, mode: mode)
                         break
                     }
                 }
             }
         } else {
             saveCustomColor(colorHex: templateColorModel.hex,mode: mode)
         }
     }

      func saveCustomColor(colorHex: String,
                           mode: ThemeDefaultMode = .basic) {
         var variants = self.fetchSelectedVaraintsForMode(mode)
         let lineColorHex = self.getLineColorHexForCustom(bgHex: colorHex)

         let dict = ["colorName": FTTemplateColor.custom.displayTitle,
                     "colorHex": colorHex,
                     "horizontalLineColor": lineColorHex,
                     "verticalLineColor":  lineColorHex]
         let customThemeColor = FTThemeColors(dictionary: dict)
         variants.selectedColor = customThemeColor
          self.themeLibrary.storeSelectedVariants(variants, mode: mode)
     }

     func getSavedTemplateColorModelForMode(_ mode:ThemeDefaultMode) -> FTTemplateColorModel {
         let variants = self.fetchSelectedVaraintsForMode(mode)
         let reqModel = FTTemplateColorModel(color: variants.selectedColor.colorName, hex: variants.selectedColor.colorHex)
         return reqModel
     }

     func getSavedCustomColorHexForMode(_ mode:ThemeDefaultMode) -> String {
        let variants = self.fetchSelectedVaraintsForMode(mode)
        return variants.selectedColor.colorHex
    }

    // Line Height Data Communication
      func getTemplateLineHeightsData() -> [FTTemplateLineHeightModel] {
        var lineHeights = [FTTemplateLineHeightModel]()

         if let lineTypes = self.basicCategory.customizations?.lineTypes {
            for lineType in lineTypes {
                let tempLineHeight = FTTemplateLineHeightModel(lineHeight: lineType.lineType)
                lineHeights.append(tempLineHeight)
            }
        }
        return lineHeights
    }

     func saveLineHeight(_ lineHeight: FTTemplateLineHeight, mode:ThemeDefaultMode = .basic) {
        var variants = self.fetchSelectedVaraintsForMode(mode)
         if let lineType = self.basicCategory.customizations?.lineTypes.first(where: { type in
            type.lineType == lineHeight
        }) {
            variants.lineType = lineType
            self.themeLibrary.storeSelectedVariants(variants,mode: mode)
        }
    }

     func getSavedLineHeightForMode(_ mode: ThemeDefaultMode) -> FTTemplateLineHeight {
        let variants = self.fetchSelectedVaraintsForMode(mode)
        return variants.lineType.lineType
    }

     // Orientation Communication
     func saveOrientation(_ orientation: FTTemplateOrientation, mode: ThemeDefaultMode = .basic) {
         var variants = self.fetchSelectedVaraintsForMode(mode)
         variants.isLandscape = orientation.isLandscape
         self.themeLibrary.storeSelectedVariants(variants,mode: mode)
     }

     func getSavedOrientationForMode(_ mode:ThemeDefaultMode) -> FTTemplateOrientation {
         let variants = self.fetchSelectedVaraintsForMode(mode)
         var orientation: FTTemplateOrientation = .portrait
         if variants.isLandscape {
             orientation = .landscape
         }
         return orientation
     }

     func fetchThemesForMode(_ mode:ThemeDefaultMode) -> [FTBasicTemplateCategoryModel] {
         var categoryModels = [FTBasicTemplateCategoryModel]()
         let basicThemes = self.basicCategory.themes
          let selectedVariants = self.fetchSelectedVaraintsForMode(mode)
         for theme in basicThemes {
             if let paperTheme = theme as? FTPaperThemeable {
                 paperTheme.setPaperVariants(selectedVariants)
             }
         }
         let basicCategoryModel = FTBasicTemplateCategoryModel(categoryData: basicThemes, categoryTitle: self.basicCategory.categoryName)
         categoryModels.append(basicCategoryModel)
         return categoryModels
     }

     func getDefaultVariants() -> FTPaperVariants {
         let deviceManager = FTDeviceDataManager()
         let currentDevice: FTDeviceModel

         if UIDevice.current.userInterfaceIdiom == .mac {
             currentDevice = deviceManager.standardiPadDevice
         } else { // iPad scenario.
             currentDevice = deviceManager.getCurrentDevice()
         }
         let defaultLineType = self.basicCategory.getDefaultLineHeight()
         let defaultColor = self.basicCategory.getDefaultTemplateColor()
         var isLandscape = false
         if UIScreen.main.bounds.width > UIScreen.main.bounds.height {
             isLandscape = true
         }
         return FTSelectedVariants(lineType: defaultLineType, selectedDevice: currentDevice, isLandscape: isLandscape, selectedColor: defaultColor)
     }

     func fetchSelectedVaraintsForMode(_ mode: ThemeDefaultMode) -> FTPaperVariants {
         if let variants =  self.themeLibrary.fetchPreviousSelectedVariantsForMode(mode) {
             return variants
         }
         return getDefaultVariants()
     }
     func variantsForMode(_ mode:ThemeDefaultMode) -> FTBasicPaperVariants {
        FTBasicPaperVariants(color: self.getSavedTemplateColorModelForMode(mode), lineHeight: self.getSavedLineHeightForMode(mode), orientaion: self.getSavedOrientationForMode(mode), templateSize: self.getSavedTemplateSizeModelForMode(mode).size)
     }
     func basictemplateDateSourceForMode(_ mode:ThemeDefaultMode) -> FTBasicPaperVariantsDateSource {
         FTBasicPaperVariantsDateSource(colorModel: self.getTemplateColorsDataForMode(mode), lineHeightsModel: self.getTemplateLineHeightsData(), sizeModel: self.getTemplateSizeData())
     }
     func saveThemeWithVariants(_ themeWithVariants: FTSelectedPaperVariantsAndTheme, mode:ThemeDefaultMode = .basic) {
         if themeWithVariants.templateColorModel != self.getSavedTemplateColorModelForMode(mode) || themeWithVariants.templateColorModel.hex !=  self.getSavedTemplateColorModelForMode(mode).hex {
             self.saveBasicTemplateColor(themeWithVariants.templateColorModel,mode: mode)
         }
         if themeWithVariants.lineHeight != self.getSavedLineHeightForMode(mode) {
             self.saveLineHeight(themeWithVariants.lineHeight,mode: mode)
         }
         if themeWithVariants.size != self.getSavedTemplateSizeModelForMode(mode).size {
             self.saveTemplateSize(templateSize: themeWithVariants.size,mode: mode)
         }
         if themeWithVariants.orientation != self.getSavedOrientationForMode(mode) {
             self.saveOrientation(themeWithVariants.orientation,mode: mode)
         }
         FTThemesLibrary(libraryType: .papers).setDefaultTheme(themeWithVariants.theme, defaultMode:mode, withVariants: FTBasicTemplatesDataSource.shared.fetchSelectedVaraintsForMode(mode))
     }
}

private extension FTBasicTemplatesDataSource {
    private func getLineColorHexForCustom(bgHex: String) -> String {
        return FTBasicThemeCategory.getCustomLineColorHex(bgHex: bgHex)
    }
}
extension FTBasicTemplatesDataSource {
    func getLineTypeFor(lineHeight:FTTemplateLineHeight) -> FTLineType? {
        self.basicCategory.customizations?.lineTypes.first(where: {$0.lineType == lineHeight})
    }
    func getTemplateColorFor(templateColorModel: FTTemplateColorModel) -> FTThemeColors? {
        if !templateColorModel.color.isCustom {
            if let colorVariants = self.basicCategory.customizations?.color_variants {
                for colorVariant in colorVariants {
                    if let themeColor = colorVariant.colors.first(where: { tempThemeColor in
                        templateColorModel.color == tempThemeColor.colorName
                    }) {
                        return themeColor
                    }
                }
            }
        }else {
            let lineColorHex = self.getLineColorHexForCustom(bgHex: templateColorModel.hex)
            let dict = ["colorName": FTTemplateColor.custom.displayTitle,
                        "colorHex": templateColorModel.hex,
                        "horizontalLineColor": lineColorHex,
                        "verticalLineColor":  lineColorHex]
            return FTThemeColors(dictionary: dict)
        }
        return nil
    }
    func getDeviceDataFor(templateSize: FTTemplateSize) -> FTDeviceModel? {
        if let device = FTDeviceDataManager().fetchDeviceData().devices.first(where: {$0.displayName == templateSize}) {
            return device
        }else { // current device
            let currentDevice = getCurrentDeviceData()
            return currentDevice
        }
    }
    func getCurrentDeviceData() -> FTDeviceModel {
        let currentDeviceModel = FTDeviceDataManager().getCurrentDevice()
        var dict = [String: String]()
        dict["displayName"] = currentDeviceModel.displayName.displayTitle
        dict["dimension"] = currentDeviceModel.dimension
        dict["identifier"] = currentDeviceModel.identifier
        dict["dimension_land"] = currentDeviceModel.dimension_land
        dict["dimension_port"] =  currentDeviceModel.dimension_port
        dict["isiPad"] = "\(currentDeviceModel.isiPad)"
        return FTDeviceModel(dictionary: dict)
    }
}
class FTBasicPaperVariants: NSObject {
    var color:FTTemplateColorModel
    var lineHeight:FTTemplateLineHeight
    var orientaion:FTTemplateOrientation
    var templateSize:FTTemplateSize
    
    init(color: FTTemplateColorModel, lineHeight: FTTemplateLineHeight, orientaion: FTTemplateOrientation, templateSize: FTTemplateSize) {
        self.color = color
        self.lineHeight = lineHeight
        self.orientaion = orientaion
        self.templateSize = templateSize
    }
}
class FTBasicPaperVariantsDateSource: NSObject {
    var colorModel: [FTTemplateColorModel]
    var lineHeightsModel: [FTTemplateLineHeightModel]
    var sizeModel: [FTTemplateSizeModel]

    init(colorModel:[FTTemplateColorModel],lineHeightsModel: [FTTemplateLineHeightModel],sizeModel: [FTTemplateSizeModel]) {
        self.colorModel = colorModel
        self.lineHeightsModel = lineHeightsModel
        self.sizeModel   = sizeModel
    }
}
