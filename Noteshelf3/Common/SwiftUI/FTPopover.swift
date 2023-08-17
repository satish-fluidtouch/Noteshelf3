//
//  FTPopover.swift
//  Noteshelf3
//
//  Created by Narayana on 28/04/22.
//

import Foundation
import SwiftUI
import UIKit

struct FTPopover<Content: View, PopoverContent: View>: View {
    @Binding var showPopover: Bool
    var popoverSize: CGSize?
    var arrowDirections: UIPopoverArrowDirection?
    let content: () -> Content
    let popoverContent: () -> PopoverContent

    var body: some View {
        content()
            .background(
                Wrapper(showPopover: $showPopover,
                        popoverSize: popoverSize,
                        popoverContent: popoverContent,
                        arrowDirections: arrowDirections)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
    }

    struct Wrapper<PopoverContent: View>: UIViewControllerRepresentable {
        @Binding var showPopover: Bool
        let popoverSize: CGSize?
        let popoverContent: () -> PopoverContent
        var arrowDirections: UIPopoverArrowDirection?

        func makeUIViewController(
            context: UIViewControllerRepresentableContext<Wrapper<PopoverContent>>
        ) -> WrapperViewController<PopoverContent> {
            return WrapperViewController(
                popoverSize: popoverSize,
                arrowDirections: arrowDirections,
                popoverContent: popoverContent) {
                    self.showPopover = false
            }
        }

        func updateUIViewController(_ uiViewController: WrapperViewController<PopoverContent>,
                                    context: UIViewControllerRepresentableContext<Wrapper<PopoverContent>>) {
            uiViewController.updateSize(popoverSize)

            if showPopover {
                uiViewController.showPopover()
            } else {
                uiViewController.hidePopover()
            }
        }
    }

    class WrapperViewController<PopoverContent: View>: UIViewController, UIPopoverPresentationControllerDelegate {
        var popoverSize: CGSize?
        var arrowDirections: UIPopoverArrowDirection?
        let popoverContent: () -> PopoverContent
        let onDismiss: () -> Void

        var popoverVC: UIViewController?

        required init?(coder: NSCoder) { fatalError("WrapperViewController init") }
        init(popoverSize: CGSize?, arrowDirections: UIPopoverArrowDirection?,
             popoverContent: @escaping () -> PopoverContent,
             onDismiss: @escaping() -> Void) {
            self.popoverSize = popoverSize
            self.arrowDirections = arrowDirections
            self.popoverContent = popoverContent
            self.onDismiss = onDismiss
            super.init(nibName: nil, bundle: nil)
        }

        override func viewDidLoad() {
            super.viewDidLoad()
        }

        func showPopover() {
            guard popoverVC == nil else { return }
            let controller = UIHostingController(rootView: popoverContent())
            if let size = popoverSize { controller.preferredContentSize = size }
            controller.modalPresentationStyle = UIModalPresentationStyle.popover
            if let popover = controller.popoverPresentationController {
                popover.sourceView = view
                if let directions = arrowDirections {
                    popover.permittedArrowDirections = directions
                }
                popover.delegate = self
            }
            popoverVC = controller
            self.present(controller, animated: true, completion: nil)
        }

        func hidePopover() {
            guard let controller = popoverVC, !controller.isBeingDismissed else { return }
            controller.dismiss(animated: true, completion: nil)
            popoverVC = nil
        }

        func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
            popoverVC = nil
            self.onDismiss()
        }

        func updateSize(_ size: CGSize?) {
            self.popoverSize = size
            if let controller = popoverVC, let size = size {
                controller.preferredContentSize = size
            }
        }

        func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
            return .none // this is what forces popovers on iPhone
        }
    }
}
