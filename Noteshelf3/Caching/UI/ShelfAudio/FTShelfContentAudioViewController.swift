//
//  FTShelfContentAudioViewController.swift
//  Noteshelf3
//
//  Created by Siva on 27/01/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import UIKit

class FTShelfContentAudioViewController: UIHostingController<AnyView> {
    private var viewModel: FTShelfContentAudioViewModel
    private weak var delegate: FTShelfMediaDelegate?

    init(viewModel: FTShelfContentAudioViewModel = FTShelfContentAudioViewModel(), delegate: FTShelfMediaDelegate?, menuOverlayInfo: FTShelfMenuOverlayInfo) {
        self.viewModel = viewModel
        self.delegate = delegate
        super.init(rootView: AnyView(FTShelfContentAudioView(viewModel: viewModel).environmentObject(menuOverlayInfo)));

        self.viewModel.onSelect = { [weak self] audio in
            guard let shelfItem = audio.document else {
                cacheLog(.error, "Shelf item not present in the audio")
                return
            }
            self?.delegate?.openNotebook(shelfItem: shelfItem, page: audio.page)
        }
        self.viewModel.openInNewWindow = { [weak self] audio in
            guard let shelfItem = audio.document else {
                cacheLog(.error, "Shelf item not opening in new window")
                return
            }
            self?.openItemInNewWindow(shelfItem, pageIndex: audio.page)
        }
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "sidebar.recordings".localized
        self.view.backgroundColor = UIColor.appColor(.secondaryBG)
    }
}
