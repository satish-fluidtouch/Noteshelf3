//
//  FTShelfNewNoteController.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 04/10/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import PhotosUI
import Combine
import FTCommon

protocol FTShelfNewNoteDelegate: AnyObject {
    func didTapTakePhoto()
    func didTapPhotoLibrary()
    func didClickImportNotebook()
    func didClickScanDocument()
    func didTapAudioNote()
    func didTapOnNewGroup()
}

class FTShelfNewNoteController: UIHostingController<AnyView>, FTPopoverPresentable {
    var ftPresentationDelegate = FTPopoverPresentation()

    private var viewModel: FTNewNotePopoverViewModel
    private var appState: AppState
    var customTransitioningDelegate = FTCustomTransitionDelegate(with: .interaction, supportsFullScreen: false);

    init(viewModel: FTNewNotePopoverViewModel,
         appState: AppState,
         shelfViewModel: FTShelfViewModel,
         delegate: FTShelfNewNoteDelegate?) {
        self.viewModel = viewModel
        self.appState = appState
        let view = FTShelfNewNotePopoverView(viewModel: viewModel,appState: appState,delegate: delegate)
        super.init(rootView: AnyView(view.environmentObject(shelfViewModel)))
    }
    
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        self.viewModel.viewDelegate = self

        var popOverHeight: CGFloat = appState.sizeClass == .regular ? 384.0 : 420
        self.preferredContentSize = CGSize(width: 330, height: popOverHeight)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}
extension FTShelfNewNoteController: FTShelfNewNotePopoverViewDelegate {
    func dismissPopover(){
        self.dismiss(animated: true)
    }
    func didTapOnWatchRecordings(){
        let storyboard = UIStoryboard(name: "FTWatchRecordings", bundle: nil);

        let watchRecordingController = storyboard.instantiateViewController(withIdentifier: FTWatchRecordedListViewController.className) as! FTWatchRecordedListViewController;
        let popOverHeight: CGFloat = self.appState.sizeClass == .regular ? 320 : 420
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationItem.hidesBackButton = true
        self.navigationController?.preferredContentSize = CGSize(width: 330, height: popOverHeight)
        self.navigationController?.pushViewController(watchRecordingController, animated: true)
    }
}
