//
//  FTShareActionViewController.swift
//  Noteshelf Action
//
//  Created by Sameer on 15/12/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon
import FTStyles

enum FTAnimationState {
    case none
    case started
    case ended
}

class FTShareActionViewController: UIViewController, FTShareAlertDelegate {
    @IBOutlet var bottomView: UIView?
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var importButton: UIButton!
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView1WidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView1HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView2WidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView2HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView3WidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView3HeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var noteBookNameLabel: UILabel!
    private var shareActionAlertView: FTShareActionAlertView?
    private var showUnsupportedAlert = false
    private var attachmentsInfo : FTAttachmentsInfo?
    var selectedItem: FTShareItemsFetchModel?
    private let imageMaxSize = CGSize(width: 240, height: 300)
    private var animationState: FTAnimationState = .none {
        didSet {
            self.shareActionAlertView?.animationState = animationState
            if animationState == .started {
                bottomView?.isUserInteractionEnabled = false
                importButton.isUserInteractionEnabled = false
            }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let folder = selectedItem?.collection?.title ?? "Unfiled"
        let newBookText = "New Notebook"
        var title  = "\(folder) / \(newBookText)"
        if selectedItem?.type == .noteBook {
            title = "\(folder) / \(selectedItem?.noteBook?.title ?? newBookText )"
        }
        noteBookNameLabel.text = title

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if showUnsupportedAlert {
            showUnsupportedAlert = false
            self.showUnspportedFileAlert()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FTStyles.registerFonts()
        self.navigationController?.navigationBar.tintColor = UIColor.appColor(.accent)
        self.preferredContentSize = CGSize(width: 540, height: 620)
        bottomView?.layer.cornerRadius = 12
        importButton.layer.cornerRadius = 12
        containerView.addShadow(color: .black.withAlphaComponent(0.2), offset: CGSize(width: 0, height: 10), opacity: 1, shadowRadius: 20)
        imageView2.isHidden = true
        imageView3.isHidden = true
        titleLabel.text = "Notebook".localized
        importButton.setTitle("Import".localized, for: .normal)
        self.applyRotation(with: -4, for: imageView2)
        self.applyRotation(with: 4, for: imageView3)
        guard let extContext = self.extensionContext else {
            return
        }
        self.loadAlertView()
        let helper = FTExtensionAtttachmentsHelper()
        helper.loadInputAttachments(extContext) { [weak self] (attachmentsInfo) in
            guard let self = self else {
                self?.showUnsupportedAlert = true
                return
            }
            self.attachmentsInfo = attachmentsInfo
            if attachmentsInfo.hasOnlyUnSupportedFiles() {
                self.showUnsupportedAlert = true
            } else if attachmentsInfo.hasOnlyImageFiles(), !attachmentsInfo.imageItems.isEmpty {
                var images = [UIImage]()
                for (index, _image) in attachmentsInfo.imageItems.enumerated() {
                    if let image = UIImage(contentsOfFile: _image.path(percentEncoded: false)) {
                        images.append(image)
                    }
                    if index > 2 {
                        break
                    }
                }
                self.updateImages(images: images)
                self.updateCountLabel(count: attachmentsInfo.imageItems.count)
            } else if attachmentsInfo.hasOnlyWebsiteLinks() {
                self.imageForSupportedFileType(url: attachmentsInfo.websiteURLs[0]) { image in
                    self.imageView1.image = image
                    self.imageView1.layer.cornerRadius = 10
                    self.updateCountLabel(count: 1)
                }
            } else if attachmentsInfo.hasOnlyPublicImageURLs() {
                let imageURL = attachmentsInfo.publicImageURLs[0]
                let task = URLSession.shared.dataTask(with: imageURL) {[weak self] (data, _, error) in
                    guard let self = self, let imageData = data, error == nil else {
                        self?.showUnsupportedAlert = true
                        return
                    }
                    DispatchQueue.main.async() {
                        if let image = UIImage(data: imageData) {
                            self.updateImages(images: [image])
                            self.updateCountLabel(count: attachmentsInfo.publicImageURLs.count)
                        } else {
                            self.showUnsupportedAlert = true
                        }
                    }
                }
                task.resume()
            } else if attachmentsInfo.hasPublicFiles() {
                self.updateImagesForPublicUrls()
                let count = attachmentsInfo.publicURLs.count + attachmentsInfo.publicImageURLs.count
                self.updateCountLabel(count: count)
            } else {
                self.showUnsupportedAlert = true
            }
        }
        self.configureNavigationBar()
    }
    
    private func updateImages(images: [UIImage?]) {
        for (index, image) in images.enumerated() {
            switch index {
            case 0:
                imageView1.image = image
                self.imageView1.isHidden = false
                let aspectFitSize = image?.aspectFittedSize(maxSize: imageMaxSize) ?? imageMaxSize
                imageView1WidthConstraint.constant = aspectFitSize.width
                imageView1HeightConstraint.constant = aspectFitSize.height
                addRoundedCorners(imageView: self.imageView1)
            case 1:
                imageView2.image = image
                self.imageView2.isHidden = false
                let aspectFitSize = image?.aspectFittedSize(maxSize: imageMaxSize) ?? imageMaxSize
                imageView2WidthConstraint.constant = aspectFitSize.width
                imageView2HeightConstraint.constant = aspectFitSize.height
                addRoundedCorners(imageView: self.imageView2)
            case 2:
                imageView3.image = image
                self.imageView3.isHidden = false
                let aspectFitSize = image?.aspectFittedSize(maxSize: imageMaxSize) ?? imageMaxSize
                imageView3WidthConstraint.constant = aspectFitSize.width
                imageView3HeightConstraint.constant = aspectFitSize.height
                addRoundedCorners(imageView: self.imageView3)
            default:
                break
            }
        }
    }
    
    private func addRoundedCorners(imageView: UIImageView) {
        imageView.layoutIfNeeded()
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
    }
    
    private func updateImagesForPublicUrls() {
        var pdfImage: UIImage?
        var publicImage: UIImage?
        var noteshelfImage: UIImage?
        var audioImage: UIImage?
        if let attachmentsInfo {
            let audioFiles = attachmentsInfo.publicURLs.filter { eachUrl in
                return eachUrl.isAudioType
            }
            if !audioFiles.isEmpty {
                self.imageView1HeightConstraint.constant = 240
                self.imageView1WidthConstraint.constant = 240
                self.imageView1.image = UIImage(named: "audio")
                audioImage = UIImage(named: "audio")
            }
            if let publicImageUrl = attachmentsInfo.publicImageURLs.first {
                publicImage = UIImage(contentsOfFile: publicImageUrl.path)
            }
            if attachmentsInfo.hasAnyNoteShelfFiles() {
                noteshelfImage = UIImage(named: "nsbook")
            }
            if let publicUrl = attachmentsInfo.publicURLs.first {
                if publicUrl.isPDFType, let pdf = PDFDocument(url: publicUrl), let page = pdf.page(at: 0) {
                    pdfImage = page.thumbnail(of: CGSize(width: 240, height: 300), for: .mediaBox).resizedImage(imageMaxSize)
                    loadImages()
                } else if publicUrl.isSupportedFileType {
                    self.imageForSupportedFileType(url: publicUrl) { image in
                        pdfImage = image
                        loadImages()
                    }
                }
            } else {
                loadImages()
            }
            func loadImages() {
                var images = [audioImage, pdfImage,publicImage, noteshelfImage]
                images = images.filter { $0 != nil }
                self.updateImages(images: images)
            }
        }
    }
    
    private func applyRotation(with angle: CGFloat, for imageView: UIImageView) {
        imageView.transform = CGAffineTransform(rotationAngle: CGFloat(angle * .pi / 180.0))
        imageView.layer.shouldRasterize = true
        imageView.layer.rasterizationScale = UIScreen.main.scale
    }
    
    private func updateCountLabel(count: Int) {
        let text = (count > 1) ? "multiple.files": "single.file"
        let count = "\(count)"
        countLabel.text = (String(format: text.localized, count))
    }
    
     func doneButtonAction() {
        self.extensionContext?.completeRequest(returningItems: self.extensionContext?.inputItems, completionHandler: nil)
    }
    
    func hasAnyNoteshelfFiles() -> Bool {
        return self.attachmentsInfo?.hasAnyNoteShelfFiles() ?? false
    }
    
    func currentSelectedItem() -> FTShareItemsFetchModel? {
        return self.selectedItem
    }
    
    private func configureNavigationBar() {
        self.navigationItem.backButtonTitle = "Back".localized
        let leftBarButton = UIBarButtonItem(title: "Cancel".localized, style: .plain, target: self, action: #selector(didTapCancel))
        self.navigationItem.leftBarButtonItem = leftBarButton
        let titleView = UIImageView(image: UIImage(named: "noteshelf"))
        titleView.frame.size = CGSize(width: 36, height: 36)
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.clearFaceFont(for: .medium, with: 20)]
        self.navigationItem.titleView = titleView
    }
    
    @IBAction func didTapButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "MainInterface", bundle: Bundle(for: FTShareActionItemsViewController.self))
        guard let vc = storyboard.instantiateViewController(withIdentifier: "FTShareActionItemsViewController") as? FTShareActionItemsViewController else {
            fatalError("Could not find FTShareActionItemsViewController")
        }
        let model = FTShareItemsFetchModel()
        vc.currentItemModel = model
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func didTapCancel() {
        self.extensionContext?.completeRequest(returningItems: self.extensionContext?.inputItems, completionHandler: nil)
    }
    
    @IBAction func didTapImport(_ sender: Any) {
        if let attachmentsInfo {
            if attachmentsInfo.hasOnlyImageFiles() {
                self.handleImageItems(attachmentsInfo.imageItems)
            } else if attachmentsInfo.hasOnlyWebsiteLinks() {
                self.handleWebsiteLinks()
            } else if attachmentsInfo.hasOnlyPublicImageURLs() {
                self.handleImageItems(attachmentsInfo.publicImageURLs)
            } else if attachmentsInfo.hasPublicFiles() {
                self.handlePublicUrls()
            }
        }
    }
    
    private func loadAlertView() {
        guard let view = Bundle.main.loadNibNamed("FTShareActionAlert", owner: nil, options: nil)?.first as? FTShareActionAlertView else {
            fatalError("Progarammer error, unable to find FTRecentSectionHeader")
        }
        self.shareActionAlertView = view
        self.shareActionAlertView?.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(view)
        self.shareActionAlertView?.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.shareActionAlertView?.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        self.shareActionAlertView?.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.shareActionAlertView?.heightAnchor.constraint(equalTo: self.view.heightAnchor).isActive = true
        self.shareActionAlertView?.animationState = .none
        self.shareActionAlertView?.del = self
    }
    
    func showUnspportedFileAlert() {
        bottomView?.isUserInteractionEnabled = false
        importButton.isUserInteractionEnabled = false
        self.shareActionAlertView?.showUnsupportedAlert()
    }
    
    private func handleImageItems(_ urls: [URL]) {
        self.animationState = .started
        urls.forEach { eachUrl in
            self.addImportAction(for: eachUrl)
            FTUserDefaults.defaults().userImportCount += 1;
        }
        self.shareActionAlertView?.numberOfSharedItems = urls.count
        self.animationState = .ended
    }
    
    private func handlePublicUrls() {
        if let attachmentsInfo {
            self.animationState = .started
            attachmentsInfo.publicURLs.forEach { (importedURL) in
                self.addImportAction(for: importedURL)
                FTUserDefaults.defaults().userImportCount += 1;
            }
            attachmentsInfo.publicImageURLs.forEach { (importedURL) in
                self.addImportAction(for: importedURL)
                FTUserDefaults.defaults().userImportCount += 1;
            }
            let count = attachmentsInfo.publicURLs.count + attachmentsInfo.publicImageURLs.count
            self.shareActionAlertView?.numberOfSharedItems = count
            self.animationState = .ended
        }
    }
    
   private func addImportAction(for url: URL) {
        let group = self.selectedItem?.group?.URL.relativePathWRTCollection()
        let collection = self.selectedItem?.collection?.URL.relativePathWRTCollection()
        let notebookPath = self.selectedItem?.noteBook?.URL.relativePathWRTCollection()
        FTImportStorageManager.addNewImportAction(url, group: group, collection: collection, notebook: notebookPath)
    }
    
    private func handleWebsiteLinks() {
        if let window = self.view.window, let attachmentsInfo {
            self.animationState = .started
            FTPDFConverter.shared.convertToPDF(url: attachmentsInfo.websiteURLs[0], view: window, onSuccess: {[weak self] filePath in
                guard let self = self else {return}
                self.addImportAction(for: URL(fileURLWithPath: filePath))
                self.shareActionAlertView?.numberOfSharedItems = 1
                self.animationState = .ended
            }, onFailure: { [weak self] _ in
                self?.animationState = .ended
            }, progress: { [weak self] progress in
            })
        }
    }
    
    func imageForSupportedFileType(url: URL, onCompletion : @escaping (UIImage?)->()) {
        if let window = self.view.window {
            showActivityIndicator()
            FTPDFConverter.shared.convertToPDF(url: url, view: window, onSuccess: {[weak self] filePath in
                guard let self = self else {return}
                if let pdf = PDFDocument(url: URL(fileURLWithPath: filePath)), let page = pdf.page(at: 0) {
                    let pdfImage = page.thumbnail(of: CGSize(width: 240, height: 300), for: .mediaBox).resizedImage(imageMaxSize)
                        onCompletion(pdfImage)
                       hideActivityIndicator()
                } else {
                    hideActivityIndicator()
                }
            }, onFailure: {_  in
                self.hideActivityIndicator()
            }, progress: {_
                in
            })
        }
    }
    
    private func showActivityIndicator() {
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
    }

    private func hideActivityIndicator() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
    }
}

extension URL {
    var isPDFType : Bool {
        return self.pathExtension == "pdf"
    }
    
    var isSupportedFileType : Bool {
        let supportedFileDocsPathExtensions = ["doc","docx","ppt","pptx","xls","xlsx"];
        return supportedFileDocsPathExtensions.contains(self.pathExtension)
    }
    
    var isAudioType : Bool {
        return FTExtensionAtttachmentsHelper.supportedAudiosPathExtensions.contains(self.pathExtension.lowercased())
    }
    
    var isImageType : Bool {
        return FTExtensionAtttachmentsHelper.supportedImagePathExtensions.contains(self.pathExtension.lowercased())
    }
}

extension UIImage {
    func aspectFittedSize(maxSize: CGSize) -> CGSize {
        return CGSize.aspectFittedSize(self.size, max: maxSize)
    }
}
