//
//  FTStickersPreviewViewController.swift
//  TempletesStore
//
//  Created by Siva on 24/04/23.
//

import UIKit
import SDWebImage
import ZipArchive

class FTStickersPreviewViewController: UIViewController {
    var template: TemplateInfo!
    @IBOutlet weak var descriptionLabel: UILabel!
    var currentIndex: Int = 0 {
        didSet {
            updateDownlaodPackStatus()
        }
    }
    
    @IBOutlet weak var authorButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!

    weak var delegate: FTTemplatesPreviewDelegate? {
        didSet {
            updateDownlaodPackStatus()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        descriptionLabel.text = template.subTitle
        authorButton.setTitle(template.author, for: .normal)
        imageView.sd_imageIndicator = SDWebImageActivityIndicator.gray
        let thumbnailUrl = (template as? DiscoveryItem)?.stickersThumbnailUrl
        self.imageView.sd_setImage(with: thumbnailUrl)
        self.imageView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        self.imageView.layer.cornerRadius = 10
        self.imageView.shadowForPage()
        updateDownlaodPackStatus()
    }

    func updateDownlaodPackStatus() {
        if let templa = template as? DiscoveryItem {
            let isDownloaded = FTTemplatesCache().stickerpackisExists(fileName: templa.fileName) 
                self.delegate?.didUpdateUIFor(sticker: isDownloaded)
        }
    }

    func downloadStickersPack() async throws {

        let storeServiceApi = FTStoreService()
            guard let templa = template as? DiscoveryItem else {
                throw TemplateDownloadError.InvalidTemplate
            }
            guard let downloadUrl = templa.stickersPackUrl else {
                throw TemplateDownloadError.InvalidTemplate
            }

            let isDownloaded = FTTemplatesCache().stickerpackisExists(fileName: templa.fileName)
            self.delegate?.didUpdateUIFor(sticker: isDownloaded)
            if isDownloaded {
                return
            }
            self.parent?.showingLoadingindicator()
            do {
                _ = try await storeServiceApi.downloadStickersFor(url: downloadUrl, fileName: templa.fileName)
                self.parent?.hideLoadingindicator()
                let alertVc = UIAlertController(title: "templatesStore.alert.success".localized, message: String(format: "templatesStore.stickerPreview.alert.successMessage".localized, templa.displayTitle), preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: "templatesStore.alert.ok".localized, style: .default))
                self.present(alertVc, animated: true)
                self.delegate?.didUpdateUIFor(sticker: true)

            } catch {
                UIAlertController.showAlert(withTitle: "templatesStore.alert.error".localized, message: error.localizedDescription, from: self, withCompletionHandler: nil)
                self.parent?.hideLoadingindicator()
                self.delegate?.didUpdateUIFor(sticker: false)
            }
    }

    @IBAction func authorAction(_ sender: Any) {
        if let openUrl = template.link, let url = URL(string: openUrl) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}
