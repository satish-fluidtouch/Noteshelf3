//
//  FTDocumentPicker.swift
//  Noteshelf3
//
//  Created by Narayana on 07/06/22.
//

import SwiftUI
import FTCommon

// https://www.hackingwithswift.com/forums/swiftui/issues-with-swiftui-s-fileimporter-modifier-with-documentgroup-based-app-ipados/7603
// Once fileImporter works properly, need to avoid the UIKIt approach
struct FTDocumentPickerView: UIViewControllerRepresentable {
    let onDocPicked: ([URL], UIViewController) -> Void

    func makeCoordinator() -> Coordinator {
        return Coordinator(onDocPicked: onDocPicked)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let documentPicker = UIDocumentPickerViewController(documentTypes: supportedUTITypesForDownload(), in: .import)
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.pageSheet
        documentPicker.delegate = context.coordinator
        return documentPicker
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }


    class Coordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {
        let onDocPicked: ([URL], UIViewController) -> Void

        init(onDocPicked: @escaping ([URL], UIViewController) -> Void) {
            self.onDocPicked = onDocPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onDocPicked(urls, controller)
        }
    }
}
