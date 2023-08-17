//
//  FTPaperTemplateCenteredCollectionViewFlowLayout.swift
//  FTNewNotebook
//
//  Created by Rakesh on 30/05/23.
//

import Foundation
import UIKit

class FTPaperTemplateCenteredCollectionViewFlowLayout: UICollectionViewFlowLayout {

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let superAttributes = super.layoutAttributesForElements(in: rect) else { return nil }
        // Copy each item to prevent "UICollectionViewFlowLayout has cached frame mismatch" warning
        guard let attributes = NSArray(array: superAttributes, copyItems: true) as? [UICollectionViewLayoutAttributes] else { return nil }

        // Constants
        let leftPadding: CGFloat = 46.0
        let interItemSpacing:CFloat = 44.0

        // Tracking values
        var leftMargin: CGFloat = leftPadding // Modified to determine origin.x for each item
        var maxY: CGFloat = -1.0 // Modified to determine origin.y for each item
        var rowSizes: [[CGFloat]] = [] // Tracks the starting and ending x-values for the first and last item in the row
        var currentRow: Int = 0 // Tracks the current row
        let width = collectionView?.frame.width ?? 0;

        attributes.forEach { layoutAttribute in

            // Each layoutAttribute represents its own item
            if layoutAttribute.frame.origin.y >= maxY {

                // This layoutAttribute represents the left-most item in the row
                leftMargin = leftPadding

                // Register its origin.x in rowSizes for use later
                if rowSizes.isEmpty {
                    // Add to first row
                    rowSizes = [[leftMargin, 0]]
                } else {
                    // Append a new row
                    rowSizes.append([leftMargin, 0])
                    currentRow += 1
                }
            }

            layoutAttribute.frame.origin.x = leftMargin

            leftMargin += min(layoutAttribute.size.width, width) + CGFloat(interItemSpacing)
            maxY = max(layoutAttribute.frame.maxY, maxY)
            layoutAttribute.size.width = min(layoutAttribute.size.width, width)
            // Add right-most x value for last item in the row
            rowSizes[currentRow][1] = leftMargin - CGFloat(interItemSpacing)
        }

        // At this point, all cells are left aligned
        // Reset tracking values and add extra left padding to center align entire row
        leftMargin = leftPadding
        maxY = -1.0
        currentRow = 0
        attributes.forEach { layoutAttribute in

            // Each layoutAttribute is its own item
            if layoutAttribute.frame.origin.y >= maxY {

                // This layoutAttribute represents the left-most item in the row
                leftMargin = leftPadding

                // Need to bump it up by an appended margin
                var rowWidth = rowSizes[currentRow][1] - rowSizes[currentRow][0] // last.x - first.x
                rowWidth = min(rowWidth, width)
                let appendedMargin = (width - leftPadding  - rowWidth - leftPadding) / 2
                leftMargin += appendedMargin

                currentRow += 1
            }

            layoutAttribute.frame.origin.x = leftMargin
            layoutAttribute.size.width = min(layoutAttribute.size.width, width)
            leftMargin += min(layoutAttribute.size.width, width) + CGFloat(interItemSpacing)
            maxY = max(layoutAttribute.frame.maxY, maxY)
        }

        return attributes
    }
}
