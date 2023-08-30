//
//  FTShelfBaseView.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 19/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SwiftUI

protocol FTShelfBaseView : View {
    var viewModel: FTShelfViewModel { get}
    var gridHorizontalPadding: CGFloat {get}
}

private extension FTShelfDisplayStyle {
    var gridSpacing: CGFloat {
        switch self {
        case .Gallery,.Icon:
            return 28;
        case .List:
            return 0;
        }
    }
}

extension FTShelfBaseView {
    var gridHorizontalPadding: CGFloat {
        let isInLandscape = UIScreen.main.bounds.width > UIScreen.main.bounds.height
        var padding: CGFloat =  32
        if self.viewModel.isSidebarOpen {
            if isInLandscape {
                padding = viewModel.displayStlye == .List ? 24 : 32
            } else {
                padding = viewModel.displayStlye == .List ? 12 : 24
            }
        } else {
            padding = 44
        }
        return padding
    }

    func shelfGridView(items: [FTShelfItemViewModel], size: CGSize) -> some View {
        LazyVGrid(columns: gridItemLayout(size), alignment: .center, spacing:viewModel.displayStlye.gridSpacing) {
            ForEach(items, id: \.self) { item in
                let gridItemSize = gridItemSize(size, shelfItem: item)
                if gridItemSize != .zero {
                    FTShelfItemView(shelfItem: item,
                                    shelfItemWidth:gridItemSize.width,
                                    shelfItemHeight: gridItemSize.height)
                    .frame(width: gridItemSize.width , height: gridItemSize.height, alignment: Alignment(horizontal: .center, vertical: .bottom))
                } else {
                    EmptyView()
                }
            }
        }
        .padding(.horizontal,gridHorizontalPadding);
    }
}

//MARK: Layout related methods
private extension FTShelfBaseView {
    func gridItemLayout(_ size: CGSize) -> [GridItem] {
      let gridItem = GridItem(GridItem.Size.flexible(), spacing: interItemSpacing, alignment: .bottom)
      return Array(repeating: gridItem, count: noOfGridColumns(size))
    }

    func gridItemSize(_ size: CGSize, shelfItem: FTShelfItemViewModel) -> CGSize {
        let columnWidth = columnWidth(size)
        let titleRectHeight = FTShelfItemProperties.Constants.Notebook.titleRectHeight
        var shelfItemSize : CGSize = CGSize(width: columnWidth, height: ((columnWidth - totalHorizontalPadding) * portraitCoverHeightPercnt) + titleRectHeight)
        if(self.viewModel.displayStlye == .List) {
            shelfItemSize.height = self.viewModel.displayStlye.shelfItemSize.height
        }
        else {
            if shelfItem.coverImage.size.width > shelfItem.coverImage.size.height {
                shelfItemSize = CGSize(width:columnWidth, height: ((columnWidth - totalHorizontalPadding)*landscapeCoverHeightPercnt) + titleRectHeight)
            }
        }
        return (shelfItemSize.width > 0 && shelfItemSize.height > 0) ? shelfItemSize : .zero
    }

    private func noOfGridColumns(_ size: CGSize) -> Int {
        let style = self.viewModel.displayStlye;
        if(style == .List) {
            return 1;
        }
        
        let availableSize = size.width - (2 * gridHorizontalPadding);
        
        let cellWidth = style.shelfItemSize.width;
        let cellWidthWithSpacing = cellWidth + interItemSpacing;
        
        var maxColumns = max(Int(availableSize / cellWidthWithSpacing),(style == .Icon) ? 2 : 1) ;
        let totalWidthNeeded = (CGFloat(maxColumns) * cellWidth) + (CGFloat(maxColumns - 1) * interItemSpacing);
        if(availableSize > (totalWidthNeeded + cellWidth * 0.5)) {
            maxColumns += 1;
        }
        return maxColumns;
    }
    
    private func columnWidth(_ size: CGSize) -> CGFloat {
        let noOfColumns = self.noOfGridColumns(size)
        let totalSpacing = interItemSpacing * CGFloat(noOfColumns - 1)
        let itemWidth = (size.width - totalSpacing - (gridHorizontalPadding*2)) / CGFloat(noOfColumns)
        return itemWidth
    }

    private var portraitCoverHeightPercnt: CGFloat {
        FTShelfItemProperties.Constants.Notebook.portraitCoverHeightPercnt
    }
    
    private var landscapeCoverHeightPercnt: CGFloat {
        FTShelfItemProperties.Constants.Notebook.landscapeCoverHeightPercnt
    }
    
    private var interItemSpacing: CGFloat {
        FTShelfItemProperties.Constants.Notebook.interItemSpacing
    }

    private var totalHorizontalPadding: CGFloat {
        FTShelfItemProperties.Constants.Notebook.totalHorizontalPadding
    }
}
extension FTShelfBaseView{
     func showMinHeight(geometrySize: CGFloat) -> CGFloat {
        if viewModel.shouldShowGetStartedInfo && viewModel.isInHomeMode {
            return geometrySize > 1023 ? 218 : (geometrySize > 530 && geometrySize < 1023 ? 340 : 495)
        } else {
            return geometrySize > 680 ? 68 : 96
        }
    }
}
