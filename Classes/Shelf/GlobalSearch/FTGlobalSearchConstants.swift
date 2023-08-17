//
//  FTGlobalSearchResultHelper.swift
//  Noteshelf3
//
//  Created by Narayana on 09/02/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

struct GlobalSearchConstants {
    struct CategoryResultsCollectionViewHeight {
        static let regular: CGFloat = 168.0
        static let compact: CGFloat = 168.0
    }

    struct CategoryCellSize {
        static let regular = CGSize(width: 92, height: 104.0)
        static let compact = CGSize(width: 92, height: 104.0)
    }

    struct BookResultsCollectionViewHeight {
        static let regular: CGFloat = 313.0
        static let compact: CGFloat = 257.0
    }

    struct BookCellSize {
        static let regular = CGSize(width: 136.0, height: 245.0)
        static let compact = CGSize(width: 96, height: 200)
    }

    struct BookThumbnailSize {
        static let regular = CGSize(width: 136.0, height: 189.0)
        static let compact = CGSize(width: 96.0, height: 133.0)
    }

    struct PageResultsCollectionViewHeight {
        static let regular: CGFloat = 384.0
        static let compact: CGFloat = 288.0
    }

    struct PageCellSize {
        static let regular = CGSize(width: 200.0, height: 316.0)
        static let compact = CGSize(width: 160.0, height: 232.0)
    }

    struct PageThumbnailSize {
        struct Portrait {
            static let regular = CGSize(width: 200.0, height: 280.0)
            static let compact = CGSize(width: 136, height: 180.0)
        }

        struct Landscape {
            static let regular = CGSize(width: 200, height: 143)
            static let compact = CGSize(width: 136.0, height: 103.0)
        }
    }

    struct ResultItemSpace {
        static let regular: CGFloat = 24.0
        static let compact: CGFloat = 16.0
    }

    struct Insets {
        static let regular = UIEdgeInsets(top: 24.0, left: 24.0, bottom: 44.0, right: 24.0)
        static let compact = UIEdgeInsets(top: 24.0, left: 16.0, bottom: 32.0, right: 16.0)
    }

    struct BookCoverThumbnailRadius {
        static let left: CGFloat = 4.0
        static let right: CGFloat = 10.0
        static let equiRadius: CGFloat = 8.0
    }
}
