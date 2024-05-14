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

class FTShareActionViewController: UIViewController {
    @IBOutlet var bottomView: UIView?
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var importButton: UIButton!
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView1WidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView1HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var noteBookNameLabel: UILabel!
    private var shareActionAlertView: FTShareActionAlertView?
    private var attachmentsInfo : FTAttachmentsInfo?
    var selectedItem: FTShareItemsFetchModel?
    private var animationState: FTAnimationState = .none {
        didSet {
            self.shareActionAlertView?.animationState = animationState
            if animationState == .started {
                bottomView?.isUserInteractionEnabled = false
                importButton.isUserInteractionEnabled = false
            }
        }
    }
    private var imagesToImport = [UIImage]()
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FTStyles.registerFonts()
        self.navigationController?.navigationBar.tintColor = UIColor.appColor(.accent)
        self.preferredContentSize = CGSize(width: 540, height: 620)
        bottomView?.layer.cornerRadius = 12
        importButton.layer.cornerRadius = 12
        imageView1.layer.cornerRadius = 10
        imageView2.layer.cornerRadius = 10
        imageView3.layer.cornerRadius = 10
        imageView2.isHidden = true
        imageView3.isHidden = true
        titleLabel.text = "Notebook".localized
        importButton.setTitle("Import".localized, for: .normal)
        self.applyRotation(with: -4, for: imageView2)
        self.applyRotation(with: 4, for: imageView3)
        guard let extContext = self.extensionContext else {
            return
        }
        
        let helper = FTExtensionAtttachmentsHelper()
        helper.loadInputAttachments(extContext) { [weak self] (attachmentsInfo) in
            guard let self = self else {
                return
            }
            self.attachmentsInfo = attachmentsInfo
            if attachmentsInfo.hasOnlyImageFiles(), !attachmentsInfo.imageItems.isEmpty {
                let imageCount = attachmentsInfo.imageItems.count
                if imageCount >= 3 {
                    self.imageView2.isHidden  = false
                    self.imageView3.isHidden  = false
                } else if imageCount == 2 {
                    self.imageView2.isHidden = false
                }
                for (index, image) in attachmentsInfo.imageItems.enumerated() {
                    if index > 2 {
                        break
                    }
                    if index == 0 {
                        self.imageView1.image = image
                    } else if index == 1 {
                        self.imageView2.image = image
                    } else if index == 2 {
                        self.imageView3.image = image
                    }
                }
                self.updateCountLabel(count: attachmentsInfo.imageItems.count)
            } else if attachmentsInfo.hasOnlyWebsiteLinks() {
                //TODO - Find a way to show website image
                self.imageView1.image = UIImage(named: "website")
                self.updateCountLabel(count: 1)
            } else if attachmentsInfo.hasOnlyPublicImageURLs() {
                let imageURL = attachmentsInfo.publicImageURLs[0]
                let task = URLSession.shared.dataTask(with: imageURL) {[weak self] (data, _, error) in
                    guard let imageData = data, error == nil else {
                        return
                    }
                    DispatchQueue.main.async() {
                        if let image = UIImage(data: imageData) {
                            self?.imageView1.image = image
                            self?.imagesToImport.append(image)
                            self?.updateCountLabel(count: attachmentsInfo.publicImageURLs.count)
                        }
                    }
                }
                task.resume()
            } else if attachmentsInfo.hasPublicFiles() {
                self.updateImagesForPublicUrls()
                let count = attachmentsInfo.publicURLs.count + attachmentsInfo.imageItems.count
                self.updateCountLabel(count: count)
            }
        }
        self.configureNavigationBar()
        self.loadAlertView()
    }
    
    private func updateImagesForPublicUrls() {
        var pdfImage: UIImage?
        var publicImage: UIImage?
        if let attachmentsInfo {
            let audioFiles = attachmentsInfo.publicURLs.filter { eachUrl in
                return eachUrl.isAudioType
            }
            if !audioFiles.isEmpty {
                self.imageView1HeightConstraint.constant = 240
                self.imageView1WidthConstraint.constant = 240
                self.imageView1.image = UIImage(named: "audio")
            }
            for eachUrl in attachmentsInfo.publicURLs {
                if eachUrl.isPDFType, let pdf = PDFDocument(url: eachUrl), let page = pdf.page(at: 0) {
                    pdfImage = page.thumbnail(of: CGSize(width: 240, height: 300), for: .mediaBox)
                    break
                }
            }
            if let publicImageUrl = attachmentsInfo.publicImageURLs.first {
                publicImage = UIImage(contentsOfFile: publicImageUrl.path)
            }
            if audioFiles.isEmpty {
                self.imageView1.image = pdfImage ?? UIImage(named: "website")
                self.imageView2.isHidden = false
                self.imageView2.image = publicImage
            } else {
                self.imageView2.isHidden = false
                self.imageView3.isHidden = false
                self.imageView2.image = pdfImage
                self.imageView3.image = publicImage
            }
        }
    }
    
    private func applyRotation(with angle: CGFloat, for imageView: UIImageView) {
        imageView.transform = CGAffineTransform(rotationAngle: CGFloat(angle * .pi / 180.0))
        imageView.layer.shouldRasterize = true
        imageView.layer.rasterizationScale = UIScreen.main.scale
    }
    
    private func updateCountLabel(count: Int) {
        countLabel.text = count == 1 ? "\(count) Page" : "\(count) Pages"
    }
    
    @objc func doneTapped() {
        self.extensionContext?.completeRequest(returningItems: self.extensionContext?.inputItems, completionHandler: nil)
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
                self.handleImageItems(attachmentsInfo.publicImageURLs)
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
        self.shareActionAlertView?.widthAnchor.constraint(equalToConstant: 270).isActive = true
        self.shareActionAlertView?.heightAnchor.constraint(equalToConstant: 240).isActive = true
        self.shareActionAlertView?.animationState = .none
        self.shareActionAlertView?.doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
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
            }
            attachmentsInfo.publicImageURLs.forEach { (importedURL) in
                self.addImportAction(for: importedURL)
            }
            FTUserDefaults.defaults().userImportCount += 1;
            if !attachmentsInfo.imageItems.isEmpty {
                self.handleImageItems(attachmentsInfo.publicImageURLs)
            }
            else {
                self.shareActionAlertView?.numberOfSharedItems = attachmentsInfo.publicURLs.count
                self.animationState = .ended
            }
        }
    }
    
   private func addImportAction(for url: URL) {
        let group = self.selectedItem?.group?.URL.relativePathWRTCollection()
        let collection = self.selectedItem?.collection?.title ?? uncategorizedShefItemCollectionTitle
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
}

extension URL {
    var isPDFType : Bool {
        return self.pathExtension == "pdf"
    }
    
    var isAudioType : Bool {
        return FTExtensionAtttachmentsHelper.supportedAudiosPathExtensions.contains(self.pathExtension.lowercased())
    }
    
    var isImageType : Bool {
        return FTExtensionAtttachmentsHelper.supportedImagePathExtensions.contains(self.pathExtension.lowercased())
    }
}
