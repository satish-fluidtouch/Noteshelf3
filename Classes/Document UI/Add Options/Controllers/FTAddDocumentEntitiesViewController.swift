//
//  FTAddDocumentEntitiesViewController.swift
//  Noteshelf
//
//  Created by Akshay on 27/09/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import PhotosUI
import Combine
import FTCommon

let TAG_MENU_TYPE_SELECTED_NAME_KEY = "kSelectedTagMenuType"
let MENU_TYPE_SELECTED_INDEX_KEY = "kSelectedMenuType"

enum AddMenuType: Int {
    case pages = 0
    case media = 1
    case externalMedia = 2
    
    var contentSize: CGSize {
        var height = CGSize(width: 320, height: 471)
        if self == .media {
            height = CGSize(width: 320, height: 415)
        } else if self == .externalMedia {
            height = CGSize(width: 320, height: 251)
        }
        return height
    }
}

protocol FTAddDocumentEntitiesViewControllerDelegate: StickerSelectionDelegate, FTAddMenuSelectImageProtocal, FTMediaLibrarySelectionDelegate {
    func didFinishPickingUIImages(_ images: [UIImage], source: FTInsertImageSource)
    func didFinishPickingImportItems(_ items: [FTImportItem]?)
    func didTapPage(_ item: FTPageType)
    func didTapMedia(_ item: MediaType)
    func didTapAttachment(_ item: AttachmentType)
}

class FTAddDocumentEntitiesViewController: UIViewController, FTPopoverPresentable {
    var ftPresentationDelegate = FTPopoverPresentation()

    override var shouldAvoidDismissOnSizeChange: Bool {
        return true
    }
    
    weak var delegate: FTAddDocumentEntitiesViewControllerDelegate?
    var canSupportDragging: Bool = false

    private var selectedPhotoType: PhotoType?
    private var selectedCameraType: CameraType?
    private var cancellable = Set<AnyCancellable>()
    private let dataManager = AddMenuDataManager()
    private let segmentConfig = UIImage.SymbolConfiguration(font: UIFont.appFont(for: .medium, with: 13))

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "Add".localized
        self.titleLabel.font = UIFont.clearFaceFont(for: .medium, with: 20)
        self.updateSegmentControlUI()
        self.removeRequiredChildren()
        self.addRequiredViewController()
    }
    
    private func addRequiredViewController() {
        if let menuType = AddMenuType(rawValue: segmentIndex) {
            switch menuType {
            case .pages:
                addPageViewController()
            case .media:
                addMediaViewController()
            case .externalMedia:
                addExternalMediaViewController()
            }
        }
    }

    private func updateSegmentControlUI() {
        self.segmentedControl?.selectedSegmentIndex = segmentIndex
        let segmentPdf = UIImage(systemName: "doc")?.withTintColor(.label).withRenderingMode(.alwaysTemplate).withConfiguration(segmentConfig)
        let segmentMedia = UIImage(systemName: "photo.on.rectangle")?.withTintColor(.label).withRenderingMode(.alwaysTemplate).withConfiguration(segmentConfig)
        let segmentAttach = UIImage(systemName: "globe")?.withTintColor(.label).withRenderingMode(.alwaysTemplate).withConfiguration(segmentConfig)

        self.segmentedControl.setImage(segmentPdf, forSegmentAt: 0)
        self.segmentedControl.setImage(segmentMedia, forSegmentAt: 1)
        self.segmentedControl.setImage(segmentAttach, forSegmentAt: 2)
    }

    class func showAsPopover(source: Any,
                             fromViewController viewController: UIViewController,
                             delegate: FTAddDocumentEntitiesViewControllerDelegate) {
        let storyboard = UIStoryboard.init(name: "FTDocumentEntity", bundle: nil)
        guard let addDocumentEntitiesViewController = storyboard.instantiateViewController(withIdentifier: "FTAddDocumentEntitiesViewController") as? FTAddDocumentEntitiesViewController else {
            fatalError("Document Entities Viewcontroller not found")
        }
        let navigationVC = UINavigationController(rootViewController: addDocumentEntitiesViewController)
        addDocumentEntitiesViewController.delegate = delegate
        addDocumentEntitiesViewController.view.backgroundColor = UIColor.clear
        addDocumentEntitiesViewController.ftPresentationDelegate.source = source as AnyObject
        viewController.ftPresentPopover(vcToPresent: navigationVC, contentSize: CGSize(width: 320, height: 384), hideNavBar: true)
    }
}

// MARK: Action - segmentControllerIndexChanged
extension FTAddDocumentEntitiesViewController {
    @IBAction func segmentControllerIndexChanged(_ sender: UISegmentedControl) {
        debugPrint("selectedSegmentIndex : \(sender.selectedSegmentIndex)")
        self.segmentIndex = sender.selectedSegmentIndex
        self.updateSegmentControlUI()
        self.removeRequiredChildren()
        self.addRequiredViewController()
    }

    private func removeRequiredChildren() {
        for child in self.children where child is UINavigationController {
            child.remove()
        }
    }
}

// MARK: - UserDefaults
extension FTAddDocumentEntitiesViewController {
    private enum SegmentKeys: String {
        case selectedSegmentIndex
    }
    
    public var segmentIndex: Int {
        get {
            UserDefaults.standard.integer(forKey: SegmentKeys.selectedSegmentIndex.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SegmentKeys.selectedSegmentIndex.rawValue)
        }
    }
}

//MARK: - Page
extension FTAddDocumentEntitiesViewController: FTAddMenuPageViewControllerDelegate {
    func addPageViewController() {
        let storyboard = UIStoryboard.init(name: "FTDocumentEntity", bundle: nil)
        guard let pageViewController = storyboard.instantiateViewController(withIdentifier: "FTAddMenuPageViewController") as? FTAddMenuPageViewController else {
            fatalError("FTAddMenuPageViewController not found")
        }
        pageViewController.delegate = self
        pageViewController.dataManager = dataManager
        addViewToParent(pageViewController)
    }
    
    func didTapPageItem(_ type: FTPageType) {
        delegate?.didTapPage(type)
    }
}

//MARK: - Media
extension FTAddDocumentEntitiesViewController: FTAddMenuMediaViewControllerDelegate {
    func addMediaViewController() {
        let storyboard = UIStoryboard.init(name: "FTDocumentEntity", bundle: nil)
        guard let mediaViewController = storyboard.instantiateViewController(withIdentifier: "FTAddMenuMediaViewController") as? FTAddMenuMediaViewController else {
            fatalError("FTAddMenuMediaViewController not found")
        }
        mediaViewController.ftPHPickerDelegare = self
        mediaViewController.cameraDelegate = self
        mediaViewController.mediaDelegate = self
        mediaViewController.dataManager = dataManager
        addViewToParent(mediaViewController)
    }
    
    func didTapMediaItem(_ item: MediaType) {
        if item == .emojis {
            pushEmojisViewController()
        } else if item == .stickers {
            pushStickersViewController()
        } else {
            self.dismiss(animated: true)
            self.delegate?.didTapMedia(item)
        }
    }

    private func pushStickersViewController() {
        let model = FTStickerCategoriesViewModel(delegate: self)
        let view = FTStickerCategoriesView(model: model,downloadedViewModel: FTDownloadedStickerViewModel())
        let viewcontroller = FTStickersViewController(rootView: view)
        self.navigationController?.pushViewController(viewcontroller, animated: true)
    }

    private func pushUnsplashViewController() {
        let storyboard = UIStoryboard.init(name: "FTDocumentEntity", bundle: nil)
        guard let unsplashViewController = storyboard.instantiateViewController(withIdentifier: "FTMediaLibraryViewController") as? FTMediaLibraryViewController else {
            fatalError("FTAddMenuUnsplashViewController not found")
        }
        unsplashViewController.delegate = self.delegate
        unsplashViewController.mediaSource = .unSplash
        navigationController?.pushViewController(unsplashViewController, animated: true)
    }
    
    private func pushPixabayViewController() {
        let storyboard = UIStoryboard.init(name: "FTDocumentEntity", bundle: nil)
        guard let pixabayViewController = storyboard.instantiateViewController(withIdentifier: "FTMediaLibraryViewController") as? FTMediaLibraryViewController else {
            fatalError("FTAddMenuPixabayViewController not found")
        }
        pixabayViewController.delegate = self.delegate
        pixabayViewController.mediaSource = .pixabay
        navigationController?.pushViewController(pixabayViewController, animated: true)
    }
    
    private func pushEmojisViewController() {
        let storyboard = UIStoryboard.init(name: "FTDocumentEntity", bundle: nil)
        guard let emojisViewController = storyboard.instantiateViewController(withIdentifier: "FTEmojisViewController") as? FTEmojisViewController else {
            fatalError("FTEmojisViewController not found")
        }
        emojisViewController.delegate = self.delegate
        navigationController?.pushViewController(emojisViewController, animated: true)
    }
}
    
// MARK: - Attachment
extension FTAddDocumentEntitiesViewController {
    func addExternalMediaViewController()  {
        let storyboard = UIStoryboard.init(name: "FTDocumentEntity", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "FTExternalMediaViewController") as? FTExternalMediaViewController else {
            fatalError("FTExternalMediaViewController not found")
        }
        
        controller.dataManager = dataManager
        controller.delegate = self
        addViewToParent(controller)
    }
}

// MARK: Camera - Page From Camera, Take Photo
extension FTAddDocumentEntitiesViewController: FTAddMenuCameraDelegate, FTImagePickerDelegate {
    func didSelectCamera(_ cameraType: CameraType) {
        selectedCameraType = cameraType
        FTImagePicker.shared.showImagePickerController(from: self)
    }

    func didFinishPicking(image: UIImage, picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            self.navigationController?.dismiss(animated: true)
            if self.selectedCameraType == .pageFromCamera {
                let item = FTImportItem(image: image)
                self.delegate?.didFinishPickingImportItems([item])
            } else if self.selectedCameraType == .takePhoto {
                self.delegate?.didFinishPickingUIImages([image], source: FTInsertImageSourcePhotos)
            }
        }
    }
}

// MARK: - Photo Library, Photo Template
extension FTAddDocumentEntitiesViewController: FTAddMenuPHPickerDelegate {
    func didSelectPhotoLibrary(menuItem: PhotoType) {
        selectedPhotoType = menuItem
        FTPHPicker.shared.presentPhPickerController(from: self, photoType: menuItem)
    }
}

// MARK: - AddViewToParent
extension FTAddDocumentEntitiesViewController {
    func addViewToParent(_ childViewController: UIViewController) {
        let viewController = UINavigationController(rootViewController: childViewController)
        viewController.navigationBar.isHidden = true
        addChild(viewController)
         self.view.addSubview(viewController.view)
        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            viewController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            viewController.view.topAnchor.constraint(equalToSystemSpacingBelow: segmentedControl.bottomAnchor, multiplier: 1.5),
            viewController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
          ])
        viewController.didMove(toParent: self)
    }
}

extension FTAddDocumentEntitiesViewController: FTExternalMediaViewControllerDelegate {
    func didTapAttachmentItem(_ type: AttachmentType) {
        if type == .unsplash {
            pushUnsplashViewController()
        } else if type == .pixabay {
            pushPixabayViewController()
        } else {
            self.dismiss(animated: true)
            self.delegate?.didTapAttachment(type)
        }
    }
}

extension FTAddDocumentEntitiesViewController: FTPHPickerDelegate {
    func didFinishPicking(results: [PHPickerResult], photoType: PhotoType) {
        if photoType == .photoLibrary {
            processForImages(results: results)
        } else {
            processForImportItems(results: results)
        }
    }

    private func processForImages(results: [PHPickerResult]) {
        if self.selectedPhotoType != .photoLibrary {
            return
        }
        FTPHPicker.shared.processResultForUIImages(results: results) { phItems in
            let images = phItems.map { $0.image }
            self.navigationController?.dismiss(animated: true)
            self.delegate?.didFinishPickingUIImages(images, source: FTInsertImageSourcePhotos)
        }
    }

    private func processForImportItems(results: [PHPickerResult]) {
        FTPHPicker.shared.processResultForImportItems(results: results) { importItems in
            if !importItems.isEmpty {
                self.navigationController?.dismiss(animated: true)
                self.delegate?.didFinishPickingImportItems(importItems)
            }
        }
    }
}

extension FTAddDocumentEntitiesViewController: FTStickerdelegate {
    func didTapSticker(with image: UIImage) {
        self.delegate?.didFinishPickingUIImages([image], source: FTInsertImageSourceSticker)
        if let navVc = self.presentingViewController{
            navVc.dismiss(animated: true)
        }
    }

    func dismiss() {
        self.dismiss(animated: true)
    }
}
