//
//  FTWatchRecordedListReprasentableView.swift
//  Noteshelf3
//
//  Created by Siva on 26/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTWatchRecordedListReprasentableView: UIViewControllerRepresentable {
    weak var delegate: FTShelfViewModelProtocol?
    func makeUIViewController(context: Context) -> FTWatchRecordedListViewController {
        let storyboard = UIStoryboard(name: "FTWatchRecordings", bundle: nil);

        let watchRecordingController = storyboard.instantiateViewController(withIdentifier: FTWatchRecordedListViewController.className) as! FTWatchRecordedListViewController
        watchRecordingController.delegate = delegate
        return watchRecordingController
    }

    func updateUIViewController(_ uiViewController: FTWatchRecordedListViewController, context: Context) {
        // You can update the UIViewController if needed
    }

}

