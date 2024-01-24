//
//  FTDeviceDataManager.swift
//  FTTemplatePicker
//
//  Created by Sameer on 17/07/20.
//  Copyright © 2020 Mahesh. All rights reserved.
//

import Foundation
import FTNewNotebook

class FTDeviceDataManager: NSObject {
    
    func fetchDeviceData() -> FTDeviceMetaData  {
        var sections = FTDeviceMetaData()
        let storage = FTThemesStorage.init()
        
        if let themeInfo  = NSDictionary.init(contentsOf: storage.themesMetadataURL),let deviceData = themeInfo["deviceMetaData"] as? [String: AnyObject],let data = try? JSONSerialization.data(withJSONObject: deviceData, options: []){
                    let decoder = JSONDecoder()
                    do {
                        sections = try decoder.decode(FTDeviceMetaData.self, from: data)
                    } catch {
                        FTCLSLog("FTDeviceDataManager Error \(error)")
                    }
        }
        return sections
    }

    func getCurrentDevice() -> FTDeviceModel {

        let isIpad = UIDevice.current.userInterfaceIdiom == .phone ? 0: 1
        let dimension : String
        let dimension_land : String

        if UIDevice.current.userInterfaceIdiom == .mac {
            let standardiPadDevice = FTDeviceDataManager().standardiPadDevice
            dimension = standardiPadDevice.dimension
            dimension_land = standardiPadDevice.dimension_land
        } else { // iPad/iPhone
            dimension = self.getDeviceDemension()
            dimension_land = self.getDeviceDemension(isLandscape: true)
        }
        var dict = [String: String]()
        dict["displayName"] = UIDevice.current.userInterfaceIdiom == .phone ? "Mobile" : "iPad"
        dict["dimension"] = dimension
        dict["identifier"] = UIDevice.current.name
        dict["dimension_land"] = dimension_land
        dict["dimension_port"] = dimension
        dict["isiPad"] = "\(isIpad)"

        let currentDeviceModel = FTDeviceModel(dictionary: dict)
        return currentDeviceModel
    }
    var standardiPadDevice: FTDeviceModel {
        var dict = [String: String]()
        dict["displayName"] = "iPad"
        dict["dimension"] = "820_1180"
        dict["identifier"] = UIDevice.current.name
        dict["dimension_land"] =  "1180_752"
        dict["dimension_port"] =  "820_1112"
        dict["isiPad"] = "1"
        
        let deviceModel = FTDeviceModel(dictionary: dict)
        return deviceModel
    }
    var standardMobileDevice: FTDeviceModel {
        var dict = [String: String]()
        dict["displayName"] = "Mobile"
        dict["dimension"] = "430_764"
        dict["identifier"] = UIDevice.current.name
        dict["dimension_land"] =  "430_764"
        dict["dimension_port"] =  "430_764"
        dict["isiPad"] = "1"

        let deviceModel = FTDeviceModel(dictionary: dict)
        return deviceModel
    }
    private func toolBarHeight() -> CGFloat {
        var extraHeight: CGFloat = 0.0
        #if !NOTESHELF_ACTION
        if let window = UIApplication.shared.keyWindow
        {
            let topSafeAreaInset = window.safeAreaInsets.top
            if topSafeAreaInset > 0 {
                extraHeight = topSafeAreaInset
            }
        }
        #endif
        return FTToolbarConfig.Height.compact + extraHeight
    }

    private func getDeviceDemension(isLandscape: Bool = false) -> String {
        let mainScreenBounds = UIScreen.main.bounds
        let deviceWidth = min(mainScreenBounds.width, mainScreenBounds.height)
        var deviceHeight = max(mainScreenBounds.width, mainScreenBounds.height)

        if UIDevice.current.userInterfaceIdiom == .phone {
            deviceHeight -= toolBarHeight() // deducting toolbar height from device to fit the paper below the toolbar.
        }

        var deviceDemension = "\(Int(deviceWidth))" + "_" + "\(Int(deviceHeight))"
        if isLandscape {
            deviceDemension = "\(Int(deviceHeight))" + "_" + "\(Int(deviceWidth))"
        }
        return deviceDemension
    }
}
