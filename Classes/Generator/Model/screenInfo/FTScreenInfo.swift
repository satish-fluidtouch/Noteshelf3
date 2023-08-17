//
//  FTScreenInfo.swift
//  Template Generator
//
//  Created by sreenu cheedella on 30/12/19.
//  Copyright © 2019 Amar. All rights reserved.
//

import UIKit

class FTScreenInfo: NSObject {
    var spacesInfo: FTScreenSpacesInfo!
    var fontsInfo: FTScreenFontsInfo!
    var selectedDeviceDemension : String!
    
    required init(formatInfo: FTYearFormatInfo) {
        super.init()
        
        var fullInfo: [String: Any] = [String: Any]()
        if let fileURL = Bundle.main.url(forResource: formatInfo.templateId, withExtension: "plist",
                                         subdirectory: "assets/" + formatInfo.templateId) {
            fullInfo = NSDictionary.init(contentsOf: fileURL) as! [String: Any]
            if(nil == fullInfo[formatInfo.screenSize]) {
                if(formatInfo.screenType == .Iphone) {
                    formatInfo.screenSize = "414_896"
                }
                else {
                    formatInfo.screenSize = "834_1112"
                }
            }
            if let deviceInfo = fullInfo[formatInfo.screenSize] as? [String: NSDictionary] {
                if let orientationInfo = deviceInfo[formatInfo.orientation] as? [String: NSDictionary] {
                    if let data = try? PropertyListSerialization.data(fromPropertyList: orientationInfo, format: .binary, options: 0) {
                        let decoder = PropertyListDecoder()
                        do {
                            spacesInfo = try decoder.decode(FTScreenSpacesInfo.self, from: data)
                        } catch {
                            #if DEBUG
                                debugPrint("ScreenSpacesInfo Error \(error)");
                            #endif
                        }
                    }
                }
            }
            if let screenInfo = fullInfo["screenFontDetails"] as? [String: Any] {
                if let screenTypeInfo = screenInfo[formatInfo.screenType.rawValue] as? [String: NSDictionary] {
                    if let data = try? PropertyListSerialization.data(fromPropertyList: screenTypeInfo, format: .binary, options: 0) {
                        let decoder = PropertyListDecoder()
                        do {
                            fontsInfo = try decoder.decode(FTScreenFontsInfo.self, from: data)
                        } catch {
                            #if DEBUG
                            debugPrint("ScreenFontsInfo Error \(error)");
                            #endif
                        }
                    }
                }
            }
        }
    }
}
