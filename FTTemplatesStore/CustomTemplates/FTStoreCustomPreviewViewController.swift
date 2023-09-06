//
//  FTStoreCustomPreviewViewController.swift
//  FTTemplatesStore
//
//  Created by Siva on 23/05/23.
//

import UIKit
import SDWebImage
import QuickLook
import FTCommon

class FTStoreCustomPreviewViewController: UIViewController {

    @IBOutlet weak var fileNameTextfield: UITextField!
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var importAndCreateButton: FTCustomButton!

    var fileUrl: URL!
    override func viewDidLoad() {
        self.title = "templatesStore.custom.customTemplate".localized
        super.viewDidLoad()
        importAndCreateButton.layer.cornerRadius = 10
        preparePreviewOfFile()
        fileNameTextfield.text = fileUrl.deletingPathExtension().lastPathComponent
        // Do any additional setup after loading the view.
    }

    func preparePreviewOfFile() {
        do {
            let image = try fileUrl.generateThumbnailForFile()
            self.imageView.image = image
            if image == nil {
                guard let document = PDFDocument(url: fileUrl) else { return }
                if document.isLocked {
                    self.imageView.image = UIImage(named: "template_locked", in: storeBundle, with: nil)
                } else {
                    self.imageView.image = UIImage(named: "finder-empty-pdf-page");
                }

            }
        } catch let error {
            print("catch Eroor", error)
        }
    }

    @IBAction func cancelAction(_ sender: Any) {
        self.dismiss(animated: true)
    }

    @IBAction func createNotebookAction(_ sender: Any) {
        if let filename = fileNameTextfield.text {
            do {
                if let importedUrl = try FTStoreCustomTemplatesHandler.shared.saveFileFrom(url: fileUrl, to: filename) {
                    if let tempUrl = try FTStoreCustomTemplatesHandler.shared.tempLocationForFile(url: importedUrl) {
                        let controllerToPresentalert = self.presentingViewController ?? self
                        self.dismiss(animated: true) {
                            if FTStoreContainerHandler.shared.premiumUser?.nonPremiumQuotaReached ?? false {
                                FTStoreContainerHandler.shared.actionStream.send(.showUpgradeAlert(controller: controllerToPresentalert, feature: nil));
                            }
                            else {
                                FTStoreContainerHandler.shared.actionStream.send(.createNotebookFor(url: tempUrl))
                            }
                        }
                    }
                }
            }
            catch {
                UIAlertController.showAlert(withTitle: "templatesStore.alert.error".localized, message: error.localizedDescription, from: self, withCompletionHandler: nil)
            }
            // Track Event
            FTStoreContainerHandler.shared.actionStream.send(.track(event: EventName.customtemplate_importandcreate_tap, params: nil, screenName: ScreenName.templatesStore))

        }
    }

}
