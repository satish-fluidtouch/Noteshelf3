//
//  FTShelfBookmarksRepresentableView.swift
//  Noteshelf3
//
//  Created by Siva on 23/01/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTShelfBookmarksRepresentableView: UIViewControllerRepresentable {

    typealias UIViewControllerType = FTShelfBookmarksViewController
    weak var viewModel: FTShelfBookmarksPageModel?
    
    func makeUIViewController(context: Context) -> FTShelfBookmarksViewController {
        let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
        if let tagsController: FTShelfBookmarksViewController = storyBoard.instantiateViewController(withIdentifier: "FTShelfBookmarksViewController") as? FTShelfBookmarksViewController {
            tagsController.viewModel = self.viewModel
            // Do some configurations here if needed.
            return tagsController
        }
        return FTShelfBookmarksViewController()
    }

    func updateUIViewController(_ uiViewController: FTShelfBookmarksViewController, context: Context) {

    }
}

