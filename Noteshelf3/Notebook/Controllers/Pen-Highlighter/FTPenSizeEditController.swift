//
//  FTPenSizeEditController.swift
//  Noteshelf3
//
//  Created by Narayana on 01/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTCommon

class FTPenSizeEditController: UIHostingController<FTPenSizeEditView>, FTPopoverPresentable {
    var ftPresentationDelegate = FTPopoverPresentation()

    static let editViewSize = CGSize(width: 250.0, height: 100.0)
    private let viewModel: FTFavoriteSizeViewModel!

    init(viewModel: FTFavoriteSizeViewModel, editPosition: FavoriteSizePosition) {
        let size = viewModel.favoritePenSizes[editPosition.rawValue]
        let sizeEditView = FTPenSizeEditView(viewModel: viewModel, viewSize: FTPenSizeEditController.editViewSize, editIndex: editPosition.rawValue, favoriteSizeValue: size.size)
        self.viewModel = viewModel
        super.init(rootView: sizeEditView)
    }

    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.viewModel.saveFavoriteSizes()
    }
}
