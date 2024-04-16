//
//  CommonExtensions.swift
//  FTPenRack
//
//  Created by Simhachalam Naidu on 15/05/20.
//  Copyright © 2020 Simhachalam Naidu. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(hexWithAlphaString: String) {
        let strings = hexWithAlphaString.split(separator: "-")
        let alpha: CGFloat;
        if strings.count >= 2 {
            let stringVal = String(strings[1]).trimmingCharacters(in: .whitespacesAndNewlines);
            let floatVal = Float(stringVal) ?? 1;
            alpha = CGFloat(floatVal);
        }
        else {
            alpha = 1.0;
        }
            
        let hexString: String = strings[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: "#", with: "");
        let scanner = Scanner(string: hexString)
        var color: UInt64 = 0
        
        scanner.scanHexInt64(&color)
        
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
}
extension UIDevice
{
    static func deviceSpecificKey() -> String
    {
        let mainScreen = UIScreen.main;
        var screenBounds = mainScreen.bounds;
        screenBounds = mainScreen.coordinateSpace.convert(screenBounds, to: mainScreen.fixedCoordinateSpace);
        let width = Int(screenBounds.width);
        let height = Int(screenBounds.height);
        return "\(width)_\(height)"
    }
    static func deviceScreenType() -> FTScreenType {
        return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone ? FTScreenType.Iphone : FTScreenType.Ipad
    }
    func isPhone() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
}
