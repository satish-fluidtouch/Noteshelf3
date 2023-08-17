//
//  FTImagePickerViewController.swift
//  Noteshelf
//
//  Created by Narayana on 09/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

public protocol FTImagePickerDelegate: AnyObject {
    func didFinishPicking(image: UIImage, picker: UIImagePickerController)
}

public class FTImagePicker: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private var source: UIViewController?

    var delegate: FTImagePickerDelegate?
    public static let shared = FTImagePicker()

    private override init() {
        // With single ton class only, we are able to configure the pickercontroller delegate
        // https://stackoverflow.com/questions/62791306/phpicker-delegate-error-phpickerviewcontrollerdelegate-doesnt-respond-to-picke
    }

    public func showImagePickerController(from controller: UIViewController) {
        if let del = controller as? FTImagePickerDelegate {
            self.source = controller
            self.delegate = del
            if(!UIImagePickerController.isSourceTypeAvailable(.camera)) {
                UIAlertController.showAlertForNoCamera(from: controller.view.window?.visibleViewController)
                return
            }
            let imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = .camera
            imagePickerController.delegate = self
            imagePickerController.cameraCaptureMode = .photo
            controller.present(imagePickerController, animated: true, completion: nil)
        }
    }

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        if nil == image {
            image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        }

        guard let image = image else  {
            UIAlertController.showAlert(withTitle: "", message: NSLocalizedString("UnexpectedError", comment: "UnexpectedError"), from: self.source, withCompletionHandler: nil)
            return
        }
        delegate?.didFinishPicking(image: image, picker: picker)
    }
}
