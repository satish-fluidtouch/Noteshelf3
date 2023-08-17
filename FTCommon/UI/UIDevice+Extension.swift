//
//  File.swift
//  
//
//  Created by Narayana on 16/05/22.
//

import UIKit

public enum FTScreenType: String {
    case ipad = "ipad"
    case iphone = "iphone"
}

public extension UIDevice {
     static func deviceSpecificKey() -> String {
        let mainScreen = UIScreen.main
        var screenBounds = mainScreen.bounds
        screenBounds = mainScreen.coordinateSpace.convert(screenBounds, to: mainScreen.fixedCoordinateSpace)
        let width = Int(screenBounds.width)
        let height = Int(screenBounds.height)
        return "\(width)_\(height)"
    }

    static func deviceScreenType() -> FTScreenType {
        return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone ? FTScreenType.iphone : FTScreenType.ipad
    }

    func isPhone() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    func isIpad() -> Bool{
       return self.userInterfaceIdiom == .pad
     }
    
     func isIphone() -> Bool{
       return self.userInterfaceIdiom == .phone
     }

    func isMac() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .mac
    }

     func deviceTypeString() -> String {
       return self.isIpad() ? "iPad" : "iPhone";
     }
}
