//
//  FTTextInputAcessoryViewProtocol.swift
//  Noteshelf
//
//  Created by Mahesh on 01/12/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTTextInputIndent : Int
{
    case right
    case left
}

protocol FTTextInputAccessoryDelegate : FTTraitCollectionOverridable
{
    func textInputAccessoryDidChangeTextAlignment(_ textAlignment : NSTextAlignment);
    func textInputAccessoryDidChangeIndent(_ indent : FTTextInputIndent);
    func textInputAccessoryDidChangeStyle(_ styleFont : UIFont);
    func textInputAccessoryDidChangeTextSize(_ textSize : CGFloat);
    func textInputAccessoryDidChangeBullet(_ bulletStyle : FTBulletType);
    func textInputAccessoryDidToggleUnderline();
    func textInputAccessoryDidChangeFontTrait(_ trait : UIFontDescriptor.SymbolicTraits);

    func textInputAccessoryDidChangeFontFamily(_ fontFamily:String);
    func textInputAccessoryDidChangeFontFamilyStyle(_ fontFamilyStyle:String);
    func textInputAccessoryDidChangeColor(_ backgroundColor : UIColor);
    func textInputAccessoryDidChangeTextColor(_ textColor : UIColor);
    func textInputAccessoryDidChangeFavoriteFont(_ font : FTCustomFontInfo)
    func textInputAccessoryDidSetDefaultFontInfo(_ font : FTCustomFontInfo)

}

enum FTTextInputAccessoryViewType {
    case styles
    case textFormat

    // Text Lists
    case bullets
    case numbers
    case checkbox

    // Indents
    case rightIndent
    case leftIndent

    case backGroundColor

    // Compact
    case keyboardDown
}

protocol FTTextInputAcessoryViewProtocol {
    var itemImage: UIImage? {get}
    var type: FTTextInputAccessoryViewType {get}
}


struct FTTextFormatAccessoryView: FTTextInputAcessoryViewProtocol {
    var itemImage: UIImage? {
        return UIImage(systemName: "textformat")
    }
    
    var type: FTTextInputAccessoryViewType {
        return .textFormat
    }
}

struct FTBulletsListAccessoryView: FTTextInputAcessoryViewProtocol {
    var itemImage: UIImage? {
        return UIImage(systemName: "list.bullet")
    }
    
    var type: FTTextInputAccessoryViewType {
        return .bullets
    }
}

struct FTNumbersListAccessoryView: FTTextInputAcessoryViewProtocol {
    var itemImage: UIImage? {
        return UIImage(systemName: "list.number")
    }
    
    var type: FTTextInputAccessoryViewType {
        return .numbers
    }
}


struct FTCheckListAccessoryView: FTTextInputAcessoryViewProtocol {
    var itemImage: UIImage? {
        return UIImage(systemName: "checklist")
    }
    
    var type: FTTextInputAccessoryViewType {
        return .checkbox
    }
}


struct FTRightIndentAccessoryView: FTTextInputAcessoryViewProtocol {
    var itemImage: UIImage? {
        return UIImage(systemName: "increase.indent")
    }
    
    var type: FTTextInputAccessoryViewType {
        return .rightIndent
    }
}


struct FTLeftIndentAccessoryView: FTTextInputAcessoryViewProtocol {
    var itemImage: UIImage? {
        return UIImage(systemName: "decrease.indent")
    }
    
    var type: FTTextInputAccessoryViewType {
        return .leftIndent
    }
}

struct FTKeyboardDownAccessoryView: FTTextInputAcessoryViewProtocol {
    var itemImage: UIImage? {
        return UIImage(systemName: "keyboard.chevron.compact.down")
    }
    
    var type: FTTextInputAccessoryViewType {
        return .keyboardDown
    }
}


class FTTextInputAccessoryViewManager: NSObject {
    
    static let shared = FTTextInputAccessoryViewManager()
  
    private override init() {
    }
    
    func getShortCompactModeTextInputAcessoryItems() -> [FTTextInputAcessoryViewProtocol] {
        return [FTTextFormatAccessoryView(), FTBulletsListAccessoryView(), FTRightIndentAccessoryView(), FTLeftIndentAccessoryView(), FTKeyboardDownAccessoryView()]
    }
    
    func getLongCompactModeTextInputAcessoryItems() -> [FTTextInputAcessoryViewProtocol] {
        return [FTTextFormatAccessoryView(), FTBulletsListAccessoryView(),FTCheckListAccessoryView(), FTRightIndentAccessoryView(), FTLeftIndentAccessoryView(), FTKeyboardDownAccessoryView()]
    }
}
