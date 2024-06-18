//
//  FTPenSizeEditController.swift
//  Noteshelf3
//
//  Created by Narayana on 01/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import Combine
import FTCommon

class FTPenSizeEditModel: ObservableObject, Equatable {
    @Published var currentSize: CGFloat

    init(currentSize: CGFloat) {
        self.currentSize = currentSize
    }

    static func == (lhs: FTPenSizeEditModel, rhs: FTPenSizeEditModel) -> Bool {
        lhs.currentSize == rhs.currentSize
    }
}

class FTPenSizeEditController: UIHostingController<FTPenSizeEditView>, FTChildPresentable {
    var ftPresentationDelegate = FTChildPresentation()

    private let viewModel: FTFavoriteSizeViewModel!
    private let sizeEditModel: FTPenSizeEditModel!
    private var cancellables = [AnyCancellable]()

    static let overlaySize = CGSize(width: 250.0, height: 75.0)
    static let viewSize = CGSize(width: 304.0, height: 75.0)

    init(viewModel: FTFavoriteSizeViewModel, editPosition: FavoriteSizePosition) {
        let size = viewModel.favoritePenSizes[editPosition.rawValue]
        self.sizeEditModel = FTPenSizeEditModel(currentSize: size.size)
        let sizeEditView = FTPenSizeEditView(penType: viewModel.currentPenset.type, favoriteSizeValue: size.size, sizeEditModel: sizeEditModel, rackType: viewModel.getRackType(), placement: viewModel.getCurrentPlacement())
        self.viewModel = viewModel
        self.viewModel.sizeEditPostion = editPosition
        super.init(rootView: sizeEditView)

        self.sizeEditModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if let editIndex = self.viewModel.sizeEditPostion?.rawValue, editIndex < self.viewModel.favoritePenSizes.count{
                    self.viewModel.updateCurrentPenSize(size: self.sizeEditModel.currentSize, sizeMode: .sizeEdit)
                    self.viewModel.updateFavoriteSize(with: self.sizeEditModel.currentSize, at: editIndex)
                }
            } .store(in: &cancellables)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
    }
    
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
