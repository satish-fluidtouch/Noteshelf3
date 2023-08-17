//
//  FTCategoryItemDatasource.swift
//  Noteshelf
//
//  Created by Chandan on 26/5/16.
//
//

import FTNewNotebook

enum FTScreenType: String {
    case Ipad = "ipad"
    case Iphone = "iphone"
}
enum FTPickerDeviceType : String {
    case StandardLetter = "Letter"
    case StandardA4 = "A4"
    case Ipad = "iPad"
    case Iphone = "iPhone"
}
enum FTScreenOrientation: String {
    case Port = "Port"
    case Land = "Land"
}
@objc enum FTCoverStyle:Int{
    case `default`
    case transparent
    case audio
    case clearWhite
}

class FTBaseCategoryDatasource {
    var categoryList = [FTThemeCategory]()
    fileprivate var themeLibrary : FTThemesLibrary!;
    
    class func initiate(withType type: FTThemeType) -> FTBaseCategoryDatasource {
        switch type {
        case .cover:
            return FTCategoryCoverDatasource();
        case .paper:
            return FTCategoryPaperDatasource();
        }
    }
    
    func count()->Int{
        return (self.categoryList.count)
    }
    
    func categoryAtIndex(_ index:Int) -> FTThemeCategory {
        let model = self.categoryList[index]
        return model
    }
    
    func defaultTheme() -> FTThemeable
    {
        return self.themeLibrary.getBasicPaperCategory().themes.first!
    }
}

class FTCategoryCoverDatasource : FTBaseCategoryDatasource {
    override init() {
        super.init();
        self.themeLibrary = FTThemesLibrary.init(libraryType: .covers);
        self.categoryList = []
    }
}

class FTCategoryPaperDatasource: FTBaseCategoryDatasource {
    override init() {
        super.init();
        self.themeLibrary = FTThemesLibrary.init(libraryType: .papers)
        self.categoryList = []
    }
}

