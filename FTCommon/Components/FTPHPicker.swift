//
//  FTPHPicker.swift
//  FTCommon
//
//  Created by Narayana on 01/03/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import PhotosUI
import Combine
import UIKit

public enum PhotoType {
    case photoLibrary
    case photoTemplate
}

public struct FTPHItem {
    public var image: UIImage
    public var title: String
    init(image: UIImage, title: String) {
        self.image = image
        self.title = title
    }
}

public protocol FTPHPickerDelegate: AnyObject {
    func didFinishPicking(results: [PHPickerResult], photoType: PhotoType)
}

public class FTPHPicker: NSObject, PHPickerViewControllerDelegate {
    var delegate: FTPHPickerDelegate?
    public var cancellable = Set<AnyCancellable>()
    var photoType: PhotoType = .photoLibrary

    private override init() {
        // With single ton class only, we are able to configure the pickercontroller delegate
        // https://stackoverflow.com/questions/62791306/phpicker-delegate-error-phpickerviewcontrollerdelegate-doesnt-respond-to-picke
    }

    public static let shared = FTPHPicker()

   public func presentPhPickerController(from controller: UIViewController, selectionLimit: Int = 0, photoType: PhotoType = .photoLibrary) {
        if let del = controller as? FTPHPickerDelegate {
            self.delegate = del
            self.photoType = photoType
            let pickerVc = self.getPickerController(selectionLimit: selectionLimit)
            controller.present(pickerVc, animated: true)
        }
    }

    public func processResultForUIImages(results: [PHPickerResult], _ completon: @escaping ([FTPHItem]) -> Void) {
        results
            .publisher
            .flatMap ({ phPickerResult in
                return self.parseResult(phPickerResult: phPickerResult)
            })
            .receive(on: RunLoop.main)
            .collect()
            .sink(receiveCompletion: { _ in
                debugPrint(" receiveCompletion " )
            }, receiveValue: { items in
                debugPrint(" receiveValue : \(items.count)")
                completon(items)
            }).store(in: &cancellable)
    }


    public func parseResult(phPickerResult: PHPickerResult) -> Future<FTPHItem, Error> {
        return Future<FTPHItem, Error> { promise in
            phPickerResult.itemProvider.loadImage { phItem in
                if let item = phItem {
                    promise(.success(item))
                }
            }
        }
    }
    
   public func pushPhPickerController(from controller: UIViewController, selectionLimit: Int = 0, photoType: PhotoType = .photoLibrary) {
        if let del = controller as? FTPHPickerDelegate {
            self.delegate = del
            self.photoType = photoType
            let pickerVc = self.getPickerController(selectionLimit: selectionLimit)
            controller.navigationController?.pushViewController(pickerVc, animated: true)
        }
    }

    private func getPickerController(selectionLimit: Int) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = selectionLimit
        configuration.filter = .images
        let pickerControler = PHPickerViewController(configuration: configuration)
        pickerControler.delegate = self
        return pickerControler
    }

    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true) {
            if !results.isEmpty {
                self.delegate?.didFinishPicking(results: results, photoType: self.photoType)
            }
        }
    }
}

extension NSItemProvider {
    func loadImage(_ onCompeltion : @escaping (FTPHItem?) -> Void)
    {
        if let readType = UIImage.classForCoder() as? NSItemProviderReading.Type {
            self.loadObject(ofClass: readType) { (image, _) in
                if let image = image as? UIImage, let title = self.suggestedName {
                    let phItem = FTPHItem(image: image, title: title)
                    onCompeltion(phItem);
                }
            };
        }
        else {
            onCompeltion(nil)
        }
    }
}
