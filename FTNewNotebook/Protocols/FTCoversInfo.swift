//
//  FTCoversInfo.swift
//  FTNewNotebook
//
//  Created by Narayana on 28/02/23.
//

import UIKit

public protocol FTCustomCoverInfoDelegate: AnyObject {
    func fetchRecentCoversData() -> [FTCoverThemeModel]
    func generateCoverTheme(image: UIImage, coverType: FTCoverSelectedType) -> FTThemeable?
}

protocol FTCoverVariantDelegate: AnyObject {
    func didSelectVariant(_ name: String)
}

protocol FTCoversScrollDelegate: AnyObject {
    var variantsData: [FTCoverVariantModel] {get set}
    func didScrollToSection(_ section: Int)
}

public protocol FTCoverUpdateDelegate: AnyObject {
    func didCancelCoverSelection()
    func didUpdateCover(_ theme: FTThemeable?)
    func removeNoCoverShadow()
    func fetchCoverViewFrame() -> CGRect
    func fetchPreviousSelectedCover() -> FTThemeable?
    func animateShowContentViewBasedOn(themeType:FTThemeType)
    func animateHideContentViewBasedOn(themeType: FTThemeType)
    func handleShowAnimationCompletion(themeType: FTThemeType)
    func setDefaultCoverToNoCover(_ cover: FTThemeable)
}

public extension FTCoverUpdateDelegate {
    func removeNoCoverShadow() {}
    func didCancelCoverSelection() {}
    func fetchCoverViewFrame() -> CGRect {return .zero}
    func fetchPreviousSelectedCover() -> FTThemeable? {return nil}
    func animateShowContentViewBasedOn(themeType:FTThemeType) {}
    func animateHideContentViewBasedOn(themeType: FTThemeType) {}
    func handleShowAnimationCompletion(themeType: FTThemeType) {}
    func setDefaultCoverToNoCover(_ cover: FTThemeable){}
}

protocol FTCoverSelectionDelegate: AnyObject {
    func didTapCancelbutton()
    func didTapOnDoneButton()
    func didSelectCover(_ themeModel: FTCoverThemeModel)
    func didSelectCustomImage(_ image: UIImage)
    func didSelectUnsplash(of url: String)
    func setDefaultCoverToNoCover(_ cover: FTThemeable)
}
