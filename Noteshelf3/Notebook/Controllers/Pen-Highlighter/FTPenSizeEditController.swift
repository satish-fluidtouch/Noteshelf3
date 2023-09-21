//
//  FTPenSizeEditController.swift
//  Noteshelf3
//
//  Created by Narayana on 01/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTCommon

protocol FTPenSizeEditControllerDelegate: NSObjectProtocol {
    func removeSizeEditViewController();
}

class FTPenSizeEditController: UIHostingController<FTPenSizeEditView>, FTPopoverPresentable {
    var ftPresentationDelegate = FTPopoverPresentation()

    weak var delegate: FTPenSizeEditControllerDelegate?;
    
    static let editViewSize = CGSize(width: 250.0, height: 100.0)
    private let viewModel: FTFavoriteSizeViewModel!
    
    init(viewModel: FTFavoriteSizeViewModel, editPosition: FavoriteSizePosition) {
        let size = viewModel.favoritePenSizes[editPosition.rawValue]
        let sizeEditView = FTPenSizeEditView(viewModel: viewModel, viewSize: FTPenSizeEditController.editViewSize, editIndex: editPosition.rawValue, favoriteSizeValue: size.size)
        self.viewModel = viewModel
        super.init(rootView: sizeEditView)
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent);
        if let window = self.view.window {
            let gesture = UIPanGestureRecognizer(target: self, action: #selector(self.panGestureDidTapped(_:)));
            gesture.delegate = self;
            gesture.cancelsTouchesInView = false;
            gesture.delaysTouchesBegan = false
            gesture.delaysTouchesEnded = false;
            window.addGestureRecognizer(gesture);
        }
    }
    
    @objc private func panGestureDidTapped(_ gesture: UIPanGestureRecognizer) {
    
    }
    
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.viewModel.saveFavoriteSizes()
    }
}

extension FTPenSizeEditController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let location = touch.location(in: self.view);
        if !self.view.bounds.contains(location) {
            self.delegate?.removeSizeEditViewController();
        }
        return false;
    }
}
