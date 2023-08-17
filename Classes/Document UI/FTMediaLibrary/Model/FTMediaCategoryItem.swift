//
//  FTPixabaySegmentedItem.swift
//  FTAddOperations
//
//  Created by Siva on 09/06/20.
//  Copyright © 2020 Siva. All rights reserved.
//

import Foundation

protocol FTMediaCategoryProtocol {
    var localizedString: String { get }
    var apiImageType: String { get }
    var index: Int { get set}
}

extension FTMediaCategoryProtocol {
    var localizedString: String {
        return ""
    }
    var apiImageType: String {
        return ""
    }
    var index: Int {
        return 0
    }
}

// MARK: - PixabaySegmentedItems
struct SearchSegmentItem: FTMediaCategoryProtocol  {
    var index: Int = 0
    
    var apiImageType: String {
        return "search"
    }
    var localizedString: String {
        return ""
    }
}
struct RecentSegmentItem: FTMediaCategoryProtocol  {
    var index: Int = 0
    
    var apiImageType: String {
        return "recent"
    }
    
    var localizedString: String {
        return "Recents".localized
    }
}

struct PhotosSegmentItem: FTMediaCategoryProtocol  {
    var index: Int = 1

    var apiImageType: String {
        return "photo"
    }
    var localizedString: String {
        return "Photos".localized
    }
}
struct VectorsSegmentItem: FTMediaCategoryProtocol  {
    var index: Int = 2

    var apiImageType: String {
        return "vector"
    }
    
    var localizedString: String {
        return "Vectors".localized
    }
 
}
struct IllustrationSegmentItem: FTMediaCategoryProtocol  {
    var index: Int = 3

    var apiImageType: String {
        return "illustration"
    }
    
    var localizedString: String {
        return "Illustrations".localized
    }
}

// MARK: - UnSplashSegmentedItems
struct USSearchSegmentItem: FTMediaCategoryProtocol  {
    var index: Int = 0

    var apiImageType: String {
        return "search"
    }
    var localizedString: String {
        return ""
    }
}

struct USRecentSegmentItem: FTMediaCategoryProtocol  {
    var index: Int = 0

    var apiImageType: String {
        return "recent"
    }
    
    var localizedString: String {
        return "Recents".localized
    }
}

struct USFeaturedSegmentItem: FTMediaCategoryProtocol  {
    var index: Int = 1
    
    var apiImageType: String {
        return "Featured"
    }
    var localizedString: String {
        return "Featured".localized
    }
}
struct USWallpapersSegmentItem: FTMediaCategoryProtocol  {
    var index: Int = 2
    var apiImageType: String {
        return "Wallpapers"
    }
    var localizedString: String {
        return "Wallpapers".localized
    }
}

struct USTravelSegmentItem: FTMediaCategoryProtocol  {
    var index: Int = 3
    
    var apiImageType: String {
        return "Travel"
    }
    var localizedString: String {
        return "Travel".localized
    }
}
struct USNatureSegmentItem: FTMediaCategoryProtocol  {
    var index: Int = 4
    
    var apiImageType: String {
        return "Nature"
    }
    var localizedString: String {
        return "Nature".localized
    }
}
struct USTexturesSegmentItem: FTMediaCategoryProtocol  {
    var index: Int = 5
    
    var apiImageType: String {
        return "Textures"
    }
    var localizedString: String {
        return "Textures".localized
    }
}

struct USBusinessSegmentItem: FTMediaCategoryProtocol  {
    var index: Int = 6
    
    var apiImageType: String {
        return "Business"
    }
    var localizedString: String {
        return "Business".localized
    }
}
struct USTechnologySegmentItem: FTMediaCategoryProtocol  {
    var index: Int = 7
    
    var apiImageType: String {
        return "Technology"
    }
    var localizedString: String {
        return "Technology".localized
    }
}
struct USAnimalsSegmentItem: FTMediaCategoryProtocol  {
    var index: Int = 8
    
    var apiImageType: String {
        return "Animals"
    }
    var localizedString: String {
        return "Animals".localized
    }
}
struct USInteriorsSegmentItem: FTMediaCategoryProtocol  {
    var index: Int = 9
    
    var apiImageType: String {
        return "Interiors"
    }
    var localizedString: String {
        return "Interiors".localized
    }
}
struct USFoodSegmentItem: FTMediaCategoryProtocol  {
    var index: Int = 10
    
    var apiImageType: String {
        return "Food"
    }
    var localizedString: String {
        return "Food".localized
    }
}
struct USAthleticsSegmentItem: FTMediaCategoryProtocol  {
    var index: Int = 11
    
    var apiImageType: String {
        return "Athletics"
    }
    var localizedString: String {
        return "Athletics".localized
    }
}
struct USHealthSegmentItem: FTMediaCategoryProtocol  {
    var index: Int = 12
    var apiImageType: String {
        return "Health"
    }
    var localizedString: String {
        return "Health".localized
    }
}
struct USFilmSegmentItem: FTMediaCategoryProtocol  {
    var index: Int = 13
    
    var apiImageType: String {
        return "Film"
    }
    var localizedString: String {
        return "Film".localized
    }
}
struct USFashionSegmentItem: FTMediaCategoryProtocol  {
    var index: Int = 14
    
    var apiImageType: String {
        return "Fashion"
    }
    var localizedString: String {
        return "Fashion".localized
    }
}
struct USArtsSegmentItem: FTMediaCategoryProtocol  {
    var index: Int = 15
    
    var apiImageType: String {
        return "Arts"
    }
    var localizedString: String {
        return "Arts".localized
    }
}
struct USHistorySegmentItem: FTMediaCategoryProtocol  {
    var index: Int = 16
    
    var apiImageType: String {
        return "History"
    }
    var localizedString: String {
        return "History".localized
    }
}
