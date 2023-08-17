//
//  RecentVariants.swift
//  FTTemplatePicker
//
//  Created by Sameer on 11/08/20.
//  Copyright © 2020 Mahesh. All rights reserved.
//

import Foundation

struct FTSelectedVariants: FTPaperVariants {
    var lineType: FTLineType
    var selectedDevice: FTDeviceModel
    var isLandscape: Bool
    var selectedColor: FTThemeColors
    
    func getKey() -> String {
        let landScape = self.isLandscape ? FTDeviceOrientation.land.rawValue : FTDeviceOrientation.port.rawValue
        let key = self.selectedDevice.dimension +  "_" + landScape + "_" + self.selectedColor.colorName.displayTitle +  "_" + self.lineType.lineType.displayTitle
        return key
    }
    
    func getThumbKey() -> String{
        let key = self.isLandscape ? "thumbnail_\(FTDeviceOrientation.land.rawValue).png" : "thumbnail_\(FTDeviceOrientation.port.rawValue).png"
        return key
    }
    
    func getDeviceDemension()-> CGRect{
        let measurements = self.isLandscape ? self.selectedDevice.dimension_land.split(separator: "_") :self.selectedDevice.dimension_port.split(separator: "_")
        let width = Int(measurements[0])
        let height = Int(Double(measurements[1])!)
        return CGRect(x: 0, y: 0, width: width!, height: height)
    }
}

