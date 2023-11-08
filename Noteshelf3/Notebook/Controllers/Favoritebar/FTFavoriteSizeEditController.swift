//
//  FTFavoriteSizeEditController.swift
//  Noteshelf3
//
//  Created by Narayana on 06/11/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import Combine

protocol FTFavoriteSizeUpdateDelegate: NSObjectProtocol {
    func didChangeSize(_ size: CGFloat)
}

class FTFavoriteSizeEditController: UIHostingController<FTPenSizeEditView> {
    private let sizeEditModel: FTPenSizeEditModel!
    weak var delegate: FTFavoriteSizeUpdateDelegate?
    private var cancellables = Set<AnyCancellable>()

    init(size: CGFloat, penType: FTPenType) {
        self.sizeEditModel = FTPenSizeEditModel(currentSize: size)
        let hostView = FTPenSizeEditView(displayMode: .favoriteEdit, penType: penType, favoriteSizeValue: size, sizeEditModel: sizeEditModel)
        super.init(rootView: hostView)
        self.sizeEditModel.$currentSize
            .dropFirst()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.didChangeSize(sizeEditModel.currentSize)
            } .store(in: &cancellables)
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
