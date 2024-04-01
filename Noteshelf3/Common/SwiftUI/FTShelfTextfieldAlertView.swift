//
//  FTShelfTextfieldAlertView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 29/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//
//

import SwiftUI
import UIKit

extension UIAlertController {
    convenience init(alert: TextAlert) {
        self.init(title: alert.title, message: nil, preferredStyle: .alert)
        addTextField { $0.placeholder = alert.placeholder }
        addAction(UIAlertAction(title: alert.cancelButtonTitle, style: .cancel) { _ in
            alert.cancelAction()
        })
        let textField = self.textFields?.first
        addAction(UIAlertAction(title: alert.primaryButtonTitle, style: .default) { _ in
            alert.primaryAction(textField?.text)
        })
    }
}
struct AlertWrapper<Content: View>: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let alert: TextAlert
    let content: Content

    func makeUIViewController(context: UIViewControllerRepresentableContext<AlertWrapper>) -> UIHostingController<Content> {
        UIHostingController(rootView: content)
    }

    final class Coordinator {
        var alertController: UIAlertController?
        init(_ controller: UIAlertController? = nil) {
            self.alertController = controller
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    func updateUIViewController(_ uiViewController: UIHostingController<Content>, context: UIViewControllerRepresentableContext<AlertWrapper>) {
        uiViewController.rootView = content
        if isPresented && uiViewController.presentedViewController == nil {
            var alert = self.alert
            alert.primaryAction = {
                self.isPresented = false
                self.alert.primaryAction($0)
            }
            alert.cancelAction = {
                self.isPresented = false
                self.alert.cancelAction()
            }
            context.coordinator.alertController = UIAlertController(alert: alert)
            uiViewController.present(context.coordinator.alertController!, animated: true)
        }
        if !isPresented && uiViewController.presentedViewController == context.coordinator.alertController {
            uiViewController.dismiss(animated: true)
        }
    }
}

struct TextAlert {
    var title: String
    var placeholder: String = ""
    var primaryButtonTitle: String = "OK"
    var cancelButtonTitle: String = "Cancel"
    var primaryAction: (String?) -> ()
    var cancelAction: () -> ()
}

extension View {
    func alertWithTextField(isPresented: Binding<Bool>, _ alert: TextAlert) -> some View {
        AlertWrapper(isPresented: isPresented, alert: alert, content: self)
    }
    
    func isLargerTextEnabled(for currentSize: DynamicTypeSize) -> Bool {
        let sizes: [DynamicTypeSize] = [.accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5]
        return sizes.contains(currentSize)
    }
}



