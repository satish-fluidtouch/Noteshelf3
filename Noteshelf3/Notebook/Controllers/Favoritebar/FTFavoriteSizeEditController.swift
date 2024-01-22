//
//  FTFavoriteSizeEditController.swift
//  Noteshelf3
//
//  Created by Narayana on 06/11/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import Combine
import FTCommon

protocol FTFavoriteSizeUpdateDelegate: NSObjectProtocol {
    func didChangeSize(_ size: CGFloat)
    func didDismissCurrentsizeEditScreen()
}

extension FTFavoriteSizeUpdateDelegate {
    func didDismissCurrentsizeEditScreen() {}
}

class FTFavoriteSizeEditController: UIHostingController<FTPenSizeEditView>, FTPopoverPresentable {
    var ftPresentationDelegate = FTPopoverPresentation()

    private let sizeEditModel: FTPenSizeEditModel!
    weak var delegate: FTFavoriteSizeUpdateDelegate?
    private var cancellables = Set<AnyCancellable>()

    init(size: CGFloat, penType: FTPenType, displayMode: FTPenSizeEditViewDisplayMode = .favoriteEdit) {
        self.sizeEditModel = FTPenSizeEditModel(currentSize: size)
        let hostView = FTPenSizeEditView(displayMode: displayMode, penType: penType, favoriteSizeValue: size, sizeEditModel: sizeEditModel, rackType: penType.rackType)
        super.init(rootView: hostView)
        self.sizeEditModel.$currentSize
            .dropFirst()
            .sink { [weak self] newValue in
                guard let self = self else { return }
                self.delegate?.didChangeSize(newValue)
            } .store(in: &cancellables)
    }
    
    deinit {
        self.delegate?.didDismissCurrentsizeEditScreen()
    }

    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
    }
}
