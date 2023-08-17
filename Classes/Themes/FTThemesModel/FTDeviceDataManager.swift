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
        var standardDevice: FTDeviceModel = FTDeviceDataManager().standardiPadDevice
        if UIDevice.current.userInterfaceIdiom == .phone {
            standardDevice = FTDeviceDataManager().standardMobileDevice
        }

        let isIpad = UIDevice.current.userInterfaceIdiom == .phone ? 0: 1

        var dict = [String: String]()
        dict["displayName"] = UIDevice.current.userInterfaceIdiom == .phone ? "Mobile" : "iPad"
        dict["dimension"] = UIDevice.current.userInterfaceIdiom == .pad ? self.getDeviceDemension() : standardDevice.dimension
        dict["identifier"] = UIDevice.current.name
        dict["dimension_land"] = UIDevice.current.userInterfaceIdiom == .pad ? self.getDeviceDemension(isLandscape: true) : standardDevice.dimension_land
        dict["dimension_port"] = UIDevice.current.userInterfaceIdiom == .pad ? self.getDeviceDemension() : standardDevice.dimension_port
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
        dict["dimension"] = "792_1224"
        dict["identifier"] = UIDevice.current.name
        dict["dimension_land"] =  "792_1224"
        dict["dimension_port"] =  "792_1224"
        dict["isiPad"] = "1"

        let deviceModel = FTDeviceModel(dictionary: dict)
        return deviceModel
    }

    private func getDeviceDemension(isLandscape: Bool = false) -> String {
        let mainScreenBounds = UIScreen.main.bounds
        let deviceWidth = min(mainScreenBounds.width, mainScreenBounds.height)
        let deviceHeight = max(mainScreenBounds.width, mainScreenBounds.height)

        var deviceDemension = "\(Int(deviceWidth))" + "_" + "\(Int(deviceHeight))"
        if isLandscape {
            deviceDemension = "\(Int(deviceHeight))" + "_" + "\(Int(deviceWidth))"
        }
        return deviceDemension
    }
}
