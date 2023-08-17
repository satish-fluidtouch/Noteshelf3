//
//  UIFont_Traits_Extension.swift
//  Noteshelf
//
//  Created by Amar on 22/5/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension UIFont {
    @objc func isBoldTrait() -> Bool
    {
        return self.fontDescriptor.symbolicTraits.contains(.traitBold);
    }
    
    @objc func isItalicTrait() -> Bool
    {
        return self.fontDescriptor.symbolicTraits.contains(.traitItalic);
    }
    
    @objc func toggleBold() -> UIFont
    {
        var fontToReturn : UIFont!;
        
        if(self.isItalicTrait()) {
            fontToReturn = self.removeTrait(.traitBold);
        }
        else {
            fontToReturn = self.addTrait(.traitBold);
        }
        return fontToReturn;
    }
    
    @objc func toggleItalic() -> UIFont
    {
        var fontToReturn : UIFont!;
        
        if(self.isItalicTrait()) {
            fontToReturn = self.removeTrait(.traitItalic);
        }
        else {
            fontToReturn = self.addTrait(.traitItalic);
        }
        return fontToReturn;
    }
    
    @objc func addTrait(_ trait : UIFontDescriptor.SymbolicTraits) -> UIFont
    {
        var fontToReturn = self;
        
        var traits = self.fontDescriptor.symbolicTraits;
        if(!traits.contains(trait)) {
            traits.formUnion(trait);
            let descriptor = self.fontDescriptor.withSymbolicTraits(traits);
            if(descriptor != nil) {
                fontToReturn = UIFont.init(descriptor: descriptor!, size: self.pointSize);
            }
        }
        return fontToReturn;
    }
    
    @objc func removeTrait(_ trait : UIFontDescriptor.SymbolicTraits) -> UIFont
    {
        var fontToReturn = self;
        
        var traits = self.fontDescriptor.symbolicTraits;
        if(traits.contains(trait)) {
            _ = traits.remove(trait)!;
        }
        let descriptor = self.fontDescriptor.withSymbolicTraits(traits);
        if(descriptor != nil) {
            fontToReturn = UIFont.init(descriptor: descriptor!, size: self.pointSize);
        }
        return fontToReturn;
    }
    
    @objc func canAddTrait(_ trait : UIFontDescriptor.SymbolicTraits) -> Bool {
        let newFont = self.addTrait(trait);
        let traits = newFont.fontDescriptor.symbolicTraits;
        if(traits.contains(trait)) {
            return true
        }
        return false
        
    }
    
    @objc
    class func defaultTextFont() -> UIFont
    {
        return UIFont.init(name: "HelveticaNeue", size: CGFloat(18))!;
    }
}
