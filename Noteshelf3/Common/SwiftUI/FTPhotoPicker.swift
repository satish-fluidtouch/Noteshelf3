//
//  FTPhotoPicker.swift
//  Noteshelf3
//
//  Created by Narayana on 06/06/22.
//

import PhotosUI
import SwiftUI

struct FTPhotoPicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode)
    private var presentationMode

    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage, String, UIViewController) -> Void

    func makeCoordinator() -> Coordinator {
        return Coordinator(presentationMode: presentationMode,
                           sourceType: sourceType,
                           onImagePicked: onImagePicked)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<FTPhotoPicker>)
    -> UIViewController {
        if self.sourceType == .photoLibrary {
            var config = PHPickerConfiguration()
            config.selectionLimit = 1
            config.filter = .any(of: [.images])
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = context.coordinator
            let navVc = UINavigationController(rootViewController: picker)
            navVc.delegate = context.coordinator
            return navVc
        } else {
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = context.coordinator
            return picker
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController,
                                context: UIViewControllerRepresentableContext<FTPhotoPicker>) {
        uiViewController.view.backgroundColor = .clear
    }
}

class Coordinator: NSObject {
    private let sourceType: UIImagePickerController.SourceType
    private let onImagePicked: (UIImage, String, UIViewController) -> Void
    @Binding var presentationMode: PresentationMode

    init(presentationMode: Binding<PresentationMode>,
         sourceType: UIImagePickerController.SourceType,
         onImagePicked: @escaping (UIImage, String, UIViewController) -> Void) {
        _presentationMode = presentationMode
        self.sourceType = sourceType
        self.onImagePicked = onImagePicked
    }
}

extension Coordinator: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let uiImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.onImagePicked(uiImage, "Untitled", picker)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension Coordinator: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        if results.isEmpty {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        let itemProviders = results.map(\.itemProvider)
        for item in itemProviders {
            if item.canLoadObject(ofClass: UIImage.self) {
                item.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        if let image = image as? UIImage, let title = item.suggestedName {
                            self.onImagePicked(image, title, picker)
                        } else if let error = error {
                            print(error)
                        }
                    }
                }
            }
        }
    }
}

extension Coordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController, animated: Bool) {
        if navigationController.viewControllers.count == 1 {
            viewController.navigationController?.isNavigationBarHidden = true
        }
    }
}
