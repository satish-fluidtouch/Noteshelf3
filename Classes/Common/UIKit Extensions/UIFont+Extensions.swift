//
//  UIFont+Extensions.swift
//  Noteshelf
//
//  Created by Sameer on 13/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit
extension UIFont {
    class func getFontOptionsForFamily(_ fontFamily:String) -> [AnyHashable]? {

        var fontNames = UIFont.fontNames(forFamilyName: fontFamily)

        var results: [AnyHashable] = []

        //Regular
        for fontName in fontNames {
            if (fontName as NSString).range(of: "-").location == NSNotFound || (fontName as NSString).range(of: "Regular").location != NSNotFound {

                results.append([
                "displayName" : "Regular",
                "fontName" : fontName
                ])
                fontNames.removeAll { $0 as AnyObject === fontName as AnyObject }
                break
            }
        }

        //Book
        for fontName in fontNames {
            if fontName.ends(with: "-Book") {
                results.append([
                    "displayName" : "Book",
                    "fontName" : fontName
                ])
                fontNames.removeAll { $0 as AnyObject === fontName as AnyObject }
                break
            }
         }

        //Medium
        for fontName in fontNames {
            if fontName.ends(with: "-Medium") {
                results.append([
                    "displayName" : "Medium",
                    "fontName" : fontName
                ])
                fontNames.removeAll { $0 as AnyObject === fontName as AnyObject }
                break
            }
         }

        //Light
        for fontName in fontNames {
            if fontName.ends(with: "-Light") {
                results.append([
                 "displayName" : "Light",
                 "fontName" : fontName
                ])
                fontNames.removeAll { $0 as AnyObject === fontName as AnyObject }
                break
            }
         }

        //Thin
        for fontName in fontNames {
            if fontName.ends(with: "-Thin") {
                results.append([
                "displayName" : "Thin",
                "fontName" : fontName
                ])
                fontNames.removeAll { $0 as AnyObject === fontName as AnyObject }
                break
            }
         }

        //Roman
        for fontName in fontNames {
            if fontName.ends(with: "-Roman") {
                results.append([
                "displayName" : "Roman",
                "fontName" : fontName
                ])
                fontNames.removeAll { $0 as AnyObject === fontName as AnyObject }
                break
            }
         }

        //ItalicMT
        for fontName in fontNames {
            if fontName.ends(with: "-ItalicMT") {
                results.append([
                  "displayName" : "Italic",
                  "fontName" : fontName
                  ])
                fontNames.removeAll { $0 as AnyObject === fontName as AnyObject }
                break
            }
         }

        //Italic
        for fontName in fontNames {
            if fontName.ends(with: "-Italic") {
                results.append([
                    "displayName" : "Italic",
                    "fontName" : fontName
                    ])
                fontNames.removeAll { $0 as AnyObject === fontName as AnyObject }
                break
            }
         }

        //BookIta & BookIt
        for fontName in fontNames {
            if fontName.ends(with: "-BookIta") || fontName.ends(with: "-BookIt")  {
                results.append([
                  "displayName" : "Book Italic",
                  "fontName" : fontName
                  ])
                fontNames.removeAll { $0 as AnyObject === fontName as AnyObject }
                break
            }
         }

        //Oblique
        for fontName in fontNames {
            if fontName.ends(with: "-Oblique") {
                results.append([
                   "displayName" : "Oblique",
                   "fontName" : fontName
                   ])
                fontNames.removeAll { $0 as AnyObject === fontName as AnyObject }
                break
            }
         }

        //MediumItalic
        for fontName in fontNames {
            if fontName.ends(with: "-MediumItalic") {
                results.append([
                     "displayName" : "Medium Italic",
                     "fontName" : fontName
                     ])
                fontNames.removeAll { $0 as AnyObject === fontName as AnyObject }
                break
            }
         }

        //Bold
        for fontName in fontNames {
            if fontName.ends(with: "-Bold") {
                results.append([
                "displayName" : "Bold",
                "fontName" : fontName
                ])
                fontNames.removeAll { $0 as AnyObject === fontName as AnyObject }
                break
            }
         }

        //BoldMT
        for fontName in fontNames {
            if fontName.ends(with: "-BoldMT") {
                results.append([
                "displayName" : "Bold",
                "fontName" : fontName
                ])
                fontNames.removeAll { $0 as AnyObject === fontName as AnyObject }
                break
            }
         }

        //Black
        for fontName in fontNames {
            if fontName.ends(with: "-Black") {
                results.append([
                  "displayName" : "Black",
                  "fontName" : fontName
                  ])
                fontNames.removeAll { $0 as AnyObject === fontName as AnyObject }
                break
            }
         }

        //Wide
        for fontName in fontNames {
            if fontName.ends(with: "-Wide") {
                results.append([
                "displayName" : "Wide",
                "fontName" : fontName
                ])
                fontNames.removeAll { $0 as AnyObject === fontName as AnyObject }
                break
            }
         }

        //CondensedExtraBold
        for fontName in fontNames {
            if fontName.ends(with: "-CondensedExtraBold") {
                results.append([
                  "displayName" : "Condensed Extra Bold",
                  "fontName" : fontName
                  ])
                fontNames.removeAll { $0 as AnyObject === fontName as AnyObject }
                break
            }
         }

        //BoldItalicMT
        for fontName in fontNames {
            if fontName.ends(with: "-BoldItalicMT") {
                results.append([
                   "displayName" : "Bold Italic",
                   "fontName" : fontName
                   ])
                fontNames.removeAll { $0 as AnyObject === fontName as AnyObject }
                break
            }
         }

        //BoldItalic
        for fontName in fontNames {
            if fontName.ends(with: "-BoldItalic") {
                results.append([
                 "displayName" : "Bold Italic",
                 "fontName" : fontName
                 ])
                fontNames.removeAll { $0 as AnyObject === fontName as AnyObject }
                break
            }
         }

        //BlackItalic
        for fontName in fontNames {
            if fontName.ends(with: "-BlackItalic") {
                results.append([
                 "displayName" : "Black Italic",
                 "fontName" : fontName
                 ])
                fontNames.removeAll { $0 as AnyObject === fontName as AnyObject }
                break
            }
         }


        //BoldOblique
        for fontName in fontNames {
            if fontName.ends(with: "-BoldOblique") {
                results.append([
                   "displayName" : "Bold Oblique",
                   "fontName" : fontName
                   ])
                fontNames.removeAll { $0 as AnyObject === fontName as AnyObject }
                break
            }
         }

        if fontNames.isEmpty {
            return results
        }

        //If there are still some items, sort them and show them
        fontNames = (fontNames as NSArray).sortedArray(using: #selector(NSString.caseInsensitiveCompare(_:))) as? [String] ?? fontNames

        for fontName in fontNames {
            if (fontName as NSString).range(of: "-").location == NSNotFound {
                results.append([
                "displayName" : fontName,
                "fontName" : fontName
                ])
            } else {
                let displayName = (fontName as NSString).substring(from: (fontName as NSString).range(of: "-").location + 1)
                results.append([
                "displayName" : displayName,
                "fontName" : fontName
                ])
            }
        }
        return results
    }
}
