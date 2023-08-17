//
//  Constants.swift
//  FTNewNotebook
//
//  Created by Narayana on 20/03/23.
//

import UIKit

struct FTCovers {
    struct ContentInset {
        static let regular = UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
        static let compact = UIEdgeInsets.zero
    }

    struct PreviewCoverRadius {
        static let topLeft: CGFloat = 8.4
        static let bottomLeft: CGFloat = 8.4
        static let topRight: CGFloat = 21
        static let bottomRight: CGFloat = 21
    }

    struct ThumbnailCoverRadius {
        static let topLeft: CGFloat = 3.0
        static let bottomLeft: CGFloat = 3.0
        static let topRight: CGFloat = 7.5
        static let bottomRight: CGFloat = 7.5
    }

    struct SelectedPreviewSize {
        static let regular = CGSize(width: 336.0, height: 447.0)
        static let compact = CGSize(width: 212.0, height: 280.0)
    }

    struct Panel {
        static let regularHeight: CGFloat = 340.0
        static let compactHeight: CGFloat = 312.0
        static let variantSize = CGSize(width: 48.0, height: 32.0)
        static let variantSpacing: CGFloat = 16.0

        struct CellSize {
            static let regular = CGSize(width: 102.0, height: 165.0)
            static let compact = CGSize(width: 82.0, height: 131.0)
            static let customRegular = CGSize(width: 102.0, height: 170.0)
        }

        struct CoverSize {
            static let regular = CGSize(width: 102.0, height: 142.0)
            static let compact = CGSize(width: 82.0, height: 108.0)
        }

        struct ItemSpacing {
            static let regular: CGFloat = 16.0
            static let compact: CGFloat = 8.0
            static let customCoverRegular: CGFloat = 12.0
            static let customTypeRegular: CGFloat = 8.0
        }

        struct SectionInset {
            static let regular: CGFloat = 32.0
            static let compact: CGFloat = 24.0
            static let customCoverRegular: CGFloat = 24.0
        }

        struct Unsplash {
            static let itemSpacing: CGFloat = 8.0
            static let lineSpacing: CGFloat = 8.0
            static let sectionInset: CGFloat = 4.0
            static let cellSize = CGSize(width: 100, height: 100)
            static let compactCellSize = CGSize(width: 70, height: 70)
            static let contentInset = UIEdgeInsets(top: 0.0, left: 24.0, bottom: 0.0, right: 24.0)
            static let compactContentInset = UIEdgeInsets(top: 0.0, left: 16.0, bottom: 0.0, right: 16.0)
        }
    }
}
