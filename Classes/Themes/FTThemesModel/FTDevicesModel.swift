//
//  FTDevicesModel.swift
//  FTTemplatePicker
//
//  Created by Sameer on 15/07/20.
//  Copyright © 2020 Mahesh. All rights reserved.
//

import UIKit
import FTNewNotebook

struct FTDeviceMetaData: Codable {
    let devices: [FTDeviceModel]
    init() {
        self.devices = [FTDeviceModel]()
    }
}

struct FTDeviceModel: Codable {
    let displayName: FTTemplateSize
    let dimension: String
    let identifier: String
    let dimension_land: String
    let dimension_port: String
    let isiPad: Bool

    init(dictionary: [String: String]) {
        displayName = FTTemplateSize(rawValue: dictionary["displayName"])
        dimension = dictionary["dimension"] ?? "834_1048"
        identifier = dictionary["identifier"] ?? ""
        dimension_land = dictionary["dimension_land"] ?? "1112_770"
        dimension_port = dictionary["dimension_port"] ?? "834_1048"
        isiPad = (dictionary["isiPad"] == "1") ? true : false
    }

    func dictionaryRepresentation() -> [String: String] {
        var dict = [String: String]()
        dict["displayName"] = displayName.rawValue
        dict["dimension"] = dimension
        dict["identifier"] =  identifier
        dict["dimension_land"] =  dimension_land
        dict["dimension_port"] =  dimension_port
        dict["isiPad"] =  isiPad ? "1" : "0"
        return dict
    }
}

struct FTCategoryCustomization: Codable {
    let background_color:Bool
    let color_variants: [FTThemeColorData]
    let lineTypes: [FTLineType]
}

struct FTThemeColorData: Codable {
    let colors: [FTThemeColors]
}

struct FTThemeColors: Codable {
    var colorName: FTTemplateColor
    var colorHex: String
    var horizontalLineColor: String
    var verticalLineColor: String

    init(dictionary: [String: String]) {
        colorName = FTTemplateColor(rawValue: dictionary["colorName"])
        colorHex = dictionary["colorHex"] ?? "#F7F7F2-1.0"
        horizontalLineColor = dictionary["horizontalLineColor"] ?? "#0000-0.15"
        verticalLineColor = dictionary["verticalLineColor"] ?? "#0000-0.15"
    }

    func dictionaryRepresentation() -> [String: String] {
        var dict = [String: String]()
        dict["colorName"] = colorName.rawValue
        dict["colorHex"] =  colorHex
        dict["horizontalLineColor"] =  horizontalLineColor
        dict["verticalLineColor"] =  verticalLineColor
        return dict
    }
}

struct FTLineType: Codable {
    let lineType: FTTemplateLineHeight
    let horizontalLineSpacing: CGFloat
    let verticalLineSpacing: CGFloat

    init(dictionary: [String: String]) {
        lineType =  FTTemplateLineHeight(rawValue:  dictionary["lineType"])
        let horizontalHeight = dictionary["horizontalLineSpacing"] ?? "34"
        horizontalLineSpacing = CGFloat((horizontalHeight as NSString).floatValue)
        let verticallineHeight = dictionary["verticalLineSpacing"] ?? "34"
        verticalLineSpacing = CGFloat((verticallineHeight as NSString).floatValue)
    }

    func dictionaryRepresentation() -> [String: String] {
        var dict = [String: String]()
        dict["lineType"] = lineType.rawValue
        dict["horizontalLineSpacing"] =  "\(horizontalLineSpacing)"
        dict["verticalLineSpacing"] =  "\(verticalLineSpacing)"
        return dict
    }
}
