//
//  FTColorPicker.swift
//  Noteshelf3
//
//  Created by Narayana on 10/05/22.
//

import SwiftUI
import UIKit

extension View {
     func ftColorPickerSheet(isPresented: Binding<Bool>, selectedColorHex: Binding<String>,
                             supportsAlpha: Bool = false, title: String? = nil) -> some View {
         self.background(FTColorPickerSheet(isPresented: isPresented, selectedColorHex: selectedColorHex,
                                            supportsAlpha: supportsAlpha, title: title))
    }
}

private struct FTColorPickerSheet: UIViewRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedColorHex: String
    var supportsAlpha: Bool
    var title: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedColorHex: $selectedColorHex, isPresented: $isPresented)
    }

    class Coordinator: NSObject, UIColorPickerViewControllerDelegate, UIPopoverPresentationControllerDelegate {
        @Binding var selectedColorHex: String
        @Binding var isPresented: Bool
        var didPresent = false

        init(selectedColorHex: Binding<String>, isPresented: Binding<Bool>) {
            self._selectedColorHex = selectedColorHex
            self._isPresented = isPresented
        }

        func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor,
                                       continuously: Bool) {
            if !continuously {
                selectedColorHex = color.hexString
            }
        }
        func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
            isPresented = false
            didPresent = false
        }
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            isPresented = false
            didPresent = false
        }
    }

    func getTopViewController(from view: UIView) -> UIViewController? {
        guard var top = view.window?.rootViewController else {
            return nil
        }
        while let next = top.presentedViewController {
            top = next
        }
        return top
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isHidden = true
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if isPresented && !context.coordinator.didPresent {
            let modal = UIColorPickerViewController()
            modal.selectedColor = UIColor(hexString: selectedColorHex)
            modal.supportsAlpha = supportsAlpha
            modal.title = title
            modal.delegate = context.coordinator
            modal.modalPresentationStyle = .popover
            modal.popoverPresentationController?.delegate = context.coordinator
            modal.popoverPresentationController?.sourceView = uiView
            let top = getTopViewController(from: uiView)
            top?.present(modal, animated: true)
            context.coordinator.didPresent = true
        }
    }
}
