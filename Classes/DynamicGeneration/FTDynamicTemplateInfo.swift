//
//  FTDynamicTemplateInfo.swift
//  DynamicTemplateGeneration
//
//  Created by sreenu cheedella on 24/02/20.
//  Copyright © 2020 sreenu cheedella. All rights reserved.
//

import UIKit

enum FTLineSize: CGFloat {
    case lineWidth = 1.0
    case dottedWidth = 2.0
}

class FTDynamicTemplateInfo: NSObject {
    var codableInfo: FTDynamicTemplateCodableInfo!
    var width: Int!
    var height: Int!
    var isLandscape: Bool!
    var customVariants: FTPaperVariants!
    var lineWidth: CGFloat!
    var dottedWidth: CGFloat!
    var horizontalLineColor: String!
    var verticalLineColor: String!

    required init(_ templateInfoDict: NSDictionary,_ isLandscape: Bool, _ variants: FTPaperVariants,  _ generationType: FTGenrationType) {
        super.init()
        self.isLandscape = isLandscape
        self.customVariants =  variants
        //Using same colors as is without opacity for both thumbnails and templates as thumbnails with opacity 1 is not suiting the new design.
        self.horizontalLineColor = variants.selectedColor.horizontalLineColor
        self.verticalLineColor = variants.selectedColor.verticalLineColor
        if generationType == .template {
            self.lineWidth = FTLineSize.lineWidth.rawValue
            self.dottedWidth = FTLineSize.dottedWidth.rawValue
        } else {
            // For preview and thumbnail
            self.lineWidth = FTLineSize.lineWidth.rawValue * 2
            self.dottedWidth = FTLineSize.dottedWidth.rawValue * 2
        }
        if let data = try? PropertyListSerialization.data(fromPropertyList: templateInfoDict, format: .binary, options: 0) {
            let decoder = PropertyListDecoder()
            do {
                self.codableInfo = try decoder.decode(FTDynamicTemplateCodableInfo.self, from: data)
            } catch {
                #if DEBUG
                debugPrint("FtDynamicTemplateCodableInfo Error \(error)");
                #endif
            }
        }
        
        if codableInfo == nil {
            if let data = try? PropertyListSerialization.data(fromPropertyList: NSDictionary.init(), format: .binary, options: 0) {
                let decoder = PropertyListDecoder()
                do {
                    codableInfo = try decoder.decode(FTDynamicTemplateCodableInfo.self, from: data)
                } catch {
                    #if DEBUG
                    debugPrint("FtDynamicTemplateCodableInfo Error \(error)");
                    #endif
                }
            }
        }
        if generationType == .preview {
          setPreviewSize()
        } else if codableInfo.width == 0 && codableInfo.height == 0 {
          setTemplateSize()
//            let screenType = UIDevice.deviceScreenType()
//            if codableInfo.supportingDeviceType == FTSupportingDeviceType.iPad.rawValue {
//                setTemplateSize(forIpad: true, deviceType: screenType, safeAreaInsets)
//            } else if codableInfo.supportingDeviceType == FTSupportingDeviceType.iPhone.rawValue {
//                setTemplateSize(forIpad: false, deviceType: screenType, safeAreaInsets)
//            } else {
//                setTemplateSize(safeAreaInsets)
//            }
        } else {
            self.width = codableInfo.width
            self.height = codableInfo.height
        }
        // Changing dot color to have opacity "0.6" for dotted templates
        if generationType == .template && codableInfo.themeClassName == "FTDottedTemplateFormat"{
            self.horizontalLineColor = self.getColorWith(alpha: "0.3", color: variants.selectedColor.horizontalLineColor)
            self.verticalLineColor = self.getColorWith(alpha: "0.3", color: variants.selectedColor.verticalLineColor)
        }
    }
    private func getColorWith(alpha: String,color:String) -> String{
        let strings = color.split(separator: "-")
        let hexString: String = strings[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let lineColor = hexString + "-" + alpha
        return lineColor
    }
    func setTemplateSize() {
        let screenSize = !isLandscape ? customVariants.selectedDevice.dimension_port : customVariants.selectedDevice.dimension_land
        let measurements = screenSize.split(separator: "_")
        self.width = Int(measurements[0])
        self.height = Int(Double(measurements[1])!)
    }
    
    func setPreviewSize() {
        if customVariants.selectedDevice.isiPad {
            //Default 10.5 size
            if !self.isLandscape {
                self.width = 834
                self.height = 1048
            } else {
                self.width = 1112
                self.height = 770
            }
        } else  {
            //Default iPhoneX size
            if !self.isLandscape {
                self.width = 375
                self.height = 724
            } else {
                self.width = 812
                self.height = 331
            }
        }
    }
    
    // This method is for the device type specific (Either Ipad or Iphone)
    private func setTemplateSize(forIpad: Bool, deviceType: FTScreenType, _ safeAreaInsets: UIEdgeInsets?){
        if !forIpad && deviceType == FTScreenType.Ipad {
            if !self.isLandscape {
                self.width = 375
                self.height = 603
            } else {
                self.width = 667
                self.height = 331
            }
        } else if forIpad && deviceType == FTScreenType.Iphone {
            if !self.isLandscape {
                self.width = 768
                self.height = 960
            } else {
                self.width = 1024
                self.height = 704
            }
        } else {
            setTemplateSize()
        }
    }
}

struct FTDynamicTemplateCodableInfo: Codable {
    let width : Int
    let height : Int
    let leftMargin : CGFloat
    let topMargin : CGFloat
    let rightMargin : CGFloat
    let bottomMargin : CGFloat
    let horizontalSpacing : CGFloat
    let verticalSpacing : CGFloat
    let bgColor: String
    let horizontalLineColor: String
    let verticalLineColor: String
    let themeClassName: String
    let supportingDeviceType: Int
    
    enum CodingKeys: String, CodingKey {
        case width = "width"
        case height = "height"
        case leftMargin = "leftMargin"
        case topMargin = "topMargin"
        case rightMargin = "rightMargin"
        case bottomMargin = "bottomMargin"
        case horizontalSpacing = "horizontalSpacing"
        case verticalSpacing = "verticalSpacing"
        case bgColor = "bgColor"
        case horizontalLineColor = "horizontalLineColor"
        case verticalLineColor = "verticalLineColor"
        case themeClassName = "themeClassName"
        case supportingDeviceType = "supporting_device_type"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.width = try values.decodeIfPresent(Int.self, forKey: .width) ?? 0
        self.height = try values.decodeIfPresent(Int.self, forKey: .height) ?? 0
        self.leftMargin = try values.decodeIfPresent(CGFloat.self, forKey: .leftMargin) ?? 99
        self.topMargin = try values.decodeIfPresent(CGFloat.self, forKey: .topMargin) ?? 65
        self.rightMargin = try values.decodeIfPresent(CGFloat.self, forKey: .rightMargin) ?? 663
        self.bottomMargin = try values.decodeIfPresent(CGFloat.self, forKey: .bottomMargin) ?? 44
        self.horizontalSpacing = try values.decodeIfPresent(CGFloat.self, forKey: .horizontalSpacing) ?? 33
        self.verticalSpacing = try values.decodeIfPresent(CGFloat.self, forKey: .verticalSpacing) ?? 4
        self.bgColor = try values.decodeIfPresent(String.self, forKey: .bgColor) ?? "#FFFED6-1.0"
        self.horizontalLineColor = try values.decodeIfPresent(String.self, forKey: .horizontalLineColor) ?? "#8FBECC-1.0"
        self.verticalLineColor = try values.decodeIfPresent(String.self, forKey: .verticalLineColor) ?? "#C4A393-1.0"
        self.themeClassName = try values.decodeIfPresent(String.self, forKey: .themeClassName) ?? "FTBasicPlainTemplateFormat"
        self.supportingDeviceType = try values.decodeIfPresent(Int.self, forKey: .supportingDeviceType) ?? 0
    }
}
