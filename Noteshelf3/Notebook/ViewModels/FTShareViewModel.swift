//
//  FTShareViewModel.swift
//  Noteshelf3
//
//  Created by Narayana on 02/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation


struct FTShareOptionsInfo {
    let currentPageThumbnail: UIImage
    let bookCover: UIImage
    let currentPageNumber: Int
    let allPagesCount: Int
    let bookHasStandardCover: Bool

    init(currentPageThumbnail: UIImage, bookCover: UIImage, currentPageNumber: Int, allPagesCount: Int,bookHasStandardCover: Bool = false) {
        self.currentPageThumbnail = currentPageThumbnail
        self.bookCover = bookCover
        self.currentPageNumber = currentPageNumber
        self.allPagesCount = allPagesCount
        self.bookHasStandardCover = bookHasStandardCover
    }
}

class FTShareViewModel: NSObject {
    weak var delegate: FTShareDelegate?
    let info: FTShareOptionsInfo

    init(info:FTShareOptionsInfo) {
        self.info = info
    }
    func updateDelegate(_ delegate: FTShareDelegate?) {
        self.delegate = delegate
    }

    func handleShareOptionSelection(_ option: FTShareOption) {
        self.delegate?.didSelectShareOption(option)
    }
    func getthumbnailImage(option:FTShareOption) -> UIImage{
        let thumbnailImage: UIImage
        switch option {
        case .currentPage:
            thumbnailImage = info.currentPageThumbnail
        case .allPages:
            thumbnailImage = info.bookCover
        case .selectPages:
            thumbnailImage = UIImage(named: "select-pages") ?? UIImage()
        case .notebook:
            thumbnailImage = UIImage()
        }
        return thumbnailImage
    }
    func getPagetitleinfo(option:FTShareOption) -> String{
        let name:String
        switch option {
        case .currentPage:
            let pageno = "\(info.currentPageNumber + 1)"
            name =  String(format: NSLocalizedString("insidenotebook.share.pageno", comment: "page %@ "), pageno)
        case .allPages:
            let noofpages = "\(info.allPagesCount)"
            name =  String(format: NSLocalizedString("insidenotebook.share.pagescount", comment: "%@ pages "), noofpages)
        case .selectPages:
            name =  ""
        case .notebook:
            name =  ""
        }
        return name
    }
}
