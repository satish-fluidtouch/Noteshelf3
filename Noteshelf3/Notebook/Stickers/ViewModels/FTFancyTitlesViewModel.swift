//
//  FTFancyTitlesViewModel.swift
//  Noteshelf3
//
//  Created by Rakesh on 25/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

enum FancytitlesCategoryNames:String{
    case superBold = "Super Bold"
    case doubleLine = "Double Line"
    case handWritten = "Handwritten"
    case serif = "Serif"
    case quirky = "Quirky"
    case outline = "Outline"
    case brush = "Brush"
    case fluid = "Fluid"
}

final class FTFancyTitlesViewModel: ObservableObject {

    func getImage(fancytitlemodel:FancytitleModel,viewWidth:Double,searchText:String) -> UIImage{
        var text:NSAttributedString =  NSAttributedString()
        if fancytitlemodel.fontName == FTFancyFonts.BistroSansLine.rawValue{
            text = FTFancyTitleGenerator().newStringForBistroFontForSize(size: fancytitlemodel.fontSize, string: NSAttributedString(string: searchText))
        }else{
            text =  NSAttributedString(string: searchText,attributes: [.font: UIFont(name: fancytitlemodel.fontName, size: fancytitlemodel.fontSize ) as Any])
        }
        let stickimage = FTFancyTitleGenerator().generateImage(for:text, with: FTFancyItem(selectedFont: UIFont(name:fancytitlemodel.fontName, size: fancytitlemodel.fontSize ) ?? UIFont(), selectedStyle: fancytitlemodel.selectedStyle, selectedColor:fancytitlemodel.selectedColor, size: fancytitlemodel.fontSize, selectedGradient: fancytitlemodel.selectedGradient, selectedFontStyle: .Chiprush, plainText: searchText), viewwidth: viewWidth) ?? UIImage()

        return stickimage
    }
}
