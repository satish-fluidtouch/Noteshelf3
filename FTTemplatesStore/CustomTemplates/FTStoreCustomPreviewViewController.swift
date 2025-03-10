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
    private var actionManager: FTStoreActionManager?

    private var fileUrl: URL!

    class func controller(fileUrl: URL, actionManager: FTStoreActionManager?) -> FTStoreCustomPreviewViewController {
        guard let vc = UIStoryboard.init(name: "FTTemplatesStore", bundle: storeBundle).instantiateViewController(withIdentifier: "FTStoreCustomPreviewViewController") as? FTStoreCustomPreviewViewController else {
            fatalError("FTStoreCustomPreviewViewController not found")
        }
        vc.fileUrl = fileUrl
        vc.actionManager = actionManager
        return vc
    }

    override func viewDidLoad() {
        self.title = "templatesStore.custom.customTemplate".localized
        super.viewDidLoad()
        importAndCreateButton.layer.cornerRadius = 10
        preparePreviewOfFile()
        fileNameTextfield.text = fileUrl.deletingPathExtension().lastPathComponent
        // Do any additional setup after loading the view.
    }

    func preparePreviewOfFile() {
        self.imageView.image = UIImage(named: "finder-empty-pdf-page");
        func generteThumbnail() {
            fileUrl.generateThumbnailForPdf { image in
                if let image {
                    runInMainThread {
                        self.imageView.image = image
                    }
                }
            }
        }

        if fileUrl.pathExtension == "pdf" {
            guard let document = PDFDocument(url: fileUrl) else { return }
            if document.isLocked {
                self.imageView.image = UIImage(named: "template_locked", in: storeBundle, with: nil)
            } else {
               generteThumbnail()
            }
        } else {
            generteThumbnail()
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
                        self.dismiss(animated: true) { [weak self] in
                            if FTStorePremiumPublisher.shared.premiumUser?.nonPremiumQuotaReached ?? false {
                                FTStorePremiumPublisher.shared.actionStream.send(.showUpgradeAlert(controller: controllerToPresentalert, feature: nil));
                            }
                            else {
                                self?.actionManager?.containerActions.send(.createNotebookFor(url: tempUrl))
                            }
                        }
                    }
                }
            }
            catch {
                UIAlertController.showAlert(withTitle: "templatesStore.alert.error".localized, message: error.localizedDescription, from: self, withCompletionHandler: nil)
            }
            // Track Event
            FTStorePremiumPublisher.shared.actionStream.send(.track(event: EventName.customtemplate_importandcreate_tap, params: nil, screenName: ScreenName.templatesStore))
        }
    }

}
