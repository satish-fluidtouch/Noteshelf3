//
//  FTCustomSheet.swift
//  Noteshelf3
//
//  Created by Narayana on 28/04/22.
//

import Foundation
import SwiftUI
import UIKit

class FTFormSheetWrapper<Content: View>: UIViewController, UIPopoverPresentationControllerDelegate {
    var content: () -> Content
    var onDismiss: (() -> Void)?
    var contentSize: CGSize = .zero

    private var hostVC: UIHostingController<Content>?

    required init?(coder: NSCoder) { fatalError("Programmer error") }

    init(content: @escaping () -> Content, contentSize: CGSize) {
        self.content = content
        self.contentSize = contentSize
        super.init(nibName: nil, bundle: nil)
    }

    func show() {
        guard hostVC == nil else { return }
        let controller = UIHostingController(rootView: content())
        let navController = UINavigationController(rootViewController: controller)
        navController.isModalInPresentation = true

        navController.view.sizeToFit()
        controller.preferredContentSize = contentSize

        navController.modalPresentationStyle = .formSheet
        navController.presentationController?.delegate = self

        hostVC = controller
        controller.view.backgroundColor = .clear
        self.present(navController, animated: true, completion: nil)
    }

    func hide() {
        guard let controller = self.hostVC, !controller.isBeingDismissed else { return }
        dismiss(animated: true, completion: nil)
        hostVC = nil
    }

    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        hostVC = nil
        self.onDismiss?()
    }
}

struct FTFormSheet<Content: View>: UIViewControllerRepresentable {
    @Binding var show: Bool
    let content: () -> Content
    let contentSize: CGSize

    func makeUIViewController(context: UIViewControllerRepresentableContext<FTFormSheet<Content>>)
    -> FTFormSheetWrapper<Content> {
        let controller = FTFormSheetWrapper(content: content, contentSize: contentSize)
        controller.onDismiss = { self.show = false }
        return controller
    }

    func updateUIViewController(_ uiViewController: FTFormSheetWrapper<Content>,
                                context: UIViewControllerRepresentableContext<FTFormSheet<Content>>) {
        if show {
            uiViewController.show()
        } else {
            uiViewController.hide()
        }
    }
}
