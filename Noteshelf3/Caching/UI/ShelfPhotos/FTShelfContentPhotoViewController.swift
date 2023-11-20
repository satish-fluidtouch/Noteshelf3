//
//  FTShelfContentPhotoViewController.swift
//  Noteshelf
//
//  Created by Akshay on 22/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import UIKit

protocol FTShelfMediaDelegate: AnyObject {
    func openNotebook(shelfItem: FTShelfItemProtocol, page: Int)
}

class FTShelfContentPhotoViewController: UIHostingController<AnyView> {
    private var mediaViewModel: FTShelfContentPhotosViewModel
    private weak var delegate: FTShelfMediaDelegate?

    init(mediaViewModel: FTShelfContentPhotosViewModel = FTShelfContentPhotosViewModel(), delegate: FTShelfMediaDelegate?, menuOverlayInfo: FTShelfMenuOverlayInfo) {
        self.mediaViewModel = mediaViewModel
        self.delegate = delegate
        super.init(rootView: AnyView(FTShelfContentPhotosView(viewModel: mediaViewModel).environmentObject(menuOverlayInfo)));

        self.mediaViewModel.onSelect = { [weak self] media in
            guard let shelfItem = media.document else {
                cacheLog(.error, "Shelf item not present in the media")
                return
            }
            self?.delegate?.openNotebook(shelfItem: shelfItem, page: media.page)
        }

        self.mediaViewModel.openInNewWindow = { [weak self] media in
            guard let shelfItem = media.document else {
                cacheLog(.error, "Shelf item not present in the media")
                return
            }
            self?.openItemInNewWindow(shelfItem, pageIndex: media.page)
        }
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "sidebar.photos".localized
        self.view.backgroundColor = UIColor.appColor(.secondaryBG)
    }
}
