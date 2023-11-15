//
//  FTFavoriteColorEditController.swift
//  Noteshelf3
//
//  Created by Narayana on 06/11/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import Combine

protocol FTFavoriteColorUpdateDelegate: NSObjectProtocol {
    func didChangeColor(_ color: String)
}

class FTFavoriteColorEditController: UIHostingController<FTFavoritePresetColorsView> {
    private var cancellables = Set<AnyCancellable>()
    weak var delegate: FTFavoriteColorUpdateDelegate?
    private(set) var viewModel: FTFavoritePresetsViewModel!

    init(viewModel: FTFavoritePresetsViewModel) {
        self.viewModel = viewModel
        let hostView = FTFavoritePresetColorsView(viewModel: viewModel, selectedPage: 0)
        super.init(rootView: hostView)
        viewModel.$currentSelectedColor
            .dropFirst()
            .sink { [weak self] newValue in
                guard let self = self else { return }
                self.delegate?.didChangeColor(newValue)
            }
            .store(in: &self.cancellables)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
    }
}
