//
//  FTShelfTagsRepresentableView.swift
//  Noteshelf3
//
//  Created by Siva on 24/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTCommon

struct FTShelfTagsRepresentableView: UIViewControllerRepresentable {

    typealias UIViewControllerType = FTTagsViewController
    var tags: [FTTagModel] = []
    weak var delegate: FTTagsViewControllerDelegate?

    func makeUIViewController(context: Context) -> FTTagsViewController {
        let storyBoard = UIStoryboard.init(name: "FTDocumentEntity", bundle: nil)
        if let tagsController: FTTagsViewController = storyBoard.instantiateViewController(withIdentifier: "FTTagsViewController") as? FTTagsViewController {
            tagsController.tagsList = self.tags
            tagsController.delegate = self.delegate
            // Do some configurations here if needed.
            return tagsController
        }
        return FTTagsViewController()
    }

    func updateUIViewController(_ uiViewController: FTTagsViewController, context: Context) {

    }
}

