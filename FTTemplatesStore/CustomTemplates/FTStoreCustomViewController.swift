//
//  FTStoreCustomViewController.swift
//  TempletesStore
//
//  Created by Siva on 24/02/23.
//

import UIKit
import FTCommon
import PhotosUI

public protocol FTThemeUpdateURL : AnyObject {
    func currentSelectedURL() -> URL?
    func setCurrentSelectedURL(url: URL)
}

public extension FTThemeUpdateURL {
    func currentSelectedURL() -> URL? {
        return nil
    }
    func setCurrentSelectedURL(url: URL) {}
}

public protocol FTStoreCustomDelegate: NSObjectProtocol, FTThemeUpdateURL {
    func customController(_ contmroller: UIViewController,didSelectTemplate info: FTTemplateInfo);
    func customController(_ contmroller: UIViewController,showIAPAlert feature: String?);
    func customController(_ contmroller: UIViewController,menuShown isMenuShown: Bool);
}

class FTStoreCustomViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet var emptyView: UIView!

    private weak var delegate: FTStoreCustomDelegate?;
    private var selectedFile: URL?
    private var sourceType: Source = .none
    private var selectedIndexPath: IndexPath?
    private var customTemplateImportManager: FTCustomTemplateImportManager?
    private var storeActionManager: FTStoreActionManager?

    private var headerView: FTLibraryHeaderView? = nil
    private var importFileHandler : FTImportFileHandler?
    private var currentSize: CGSize = .zero
    private let viewModel = FTStoreCustomTemplateViewModel()

    static func controller(source: Source,
                           delegate: FTStoreCustomDelegate,
                           selectedFile: URL?,
                           customTemplateImportManager: FTCustomTemplateImportManager?,
                           storeActionManager: FTStoreActionManager?) -> UIViewController {
        let storyboard = UIStoryboard(name: "FTTemplatesStore", bundle: storeBundle)
        let viewController = storyboard.instantiateViewController(withIdentifier: "FTStoreCustomViewController") as! FTStoreCustomViewController
        viewController.delegate = delegate
        viewController.selectedFile = selectedFile
        viewController.sourceType = source
        viewController.customTemplateImportManager = customTemplateImportManager
        viewController.storeActionManager = storeActionManager
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        observers()
        initializeCollectionView()
        if sourceType != .none {
            self.view.backgroundColor = UIColor.appColor(.panelBgColor)
            self.collectionView.backgroundColor = UIColor.appColor(.panelBgColor)
        }

        viewModel.applySnapshotClosure = { [weak self] in
            self?.updateEmptyView()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadTemplates()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateFrame()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: {[weak self](_) in
            guard let self = self else { return }
            self.collectionView.reloadData()
        }, completion: { (_) in
        })
    }

    private func updateEmptyView() {
        runInMainThread {
            if self.viewModel.items().isEmpty {
                self.collectionView.backgroundView = self.emptyView
            } else {
                self.collectionView.backgroundView = nil
            }
        }
    }

    private func updateFrame() {
        let frame = self.view.frame.size;
        if currentSize.width != frame.width {
            currentSize = frame
            self.collectionView.reloadData()
        }
    }

    private func initializeCollectionView() {
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        let alignedFlowLayout = FTTagsAlignedCollectionViewFlowLayout(verticalAlignment: .bottom)
        self.collectionView.collectionViewLayout = alignedFlowLayout
        self.collectionView.delegate = self
        self.configureDatasource()
    }

    private func columnWidthForSize(_ size: CGSize) -> CGFloat {
        let noOfColumns = self.noOfColumnsForCollectionViewGrid()
        let totalSpacing = FTStoreConstants.Template.interItemSpacing * CGFloat(noOfColumns - 1)
        let itemWidth = (size.width - totalSpacing - (FTStoreConstants.Template.gridHorizontalPadding * 2)) / CGFloat(noOfColumns)
        return itemWidth
    }

    private func configureDatasource() {
        viewModel.dataSource = StoreCustomDatasource(collectionView: self.collectionView, cellProvider: { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FTStoreCustomCollectionCell.reuseIdentifier, for: indexPath) as? FTStoreCustomCollectionCell else {
                fatalError("can't dequeue FTStoreCustomCollectionCell")
            }
            cell.prepareCellWith(style: item as! FTTemplateStyle, sourceType: self.sourceType)
            return cell
        })

        viewModel.dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self = self else { return nil }
            self.headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FTLibraryHeaderView", for: indexPath) as? FTLibraryHeaderView
            // Configure the header view with data from the data source
            if let pare = self.parent as? FTStoreContainerViewController {
                if let seg = pare.topSegmentView, pare.segmentControl.selectedIndex == 2 {
                    self.headerView?.addSubview(seg)
                }
            }
            return self.headerView
        }

    }

}

// MARK: - UICollectionViewDelegate
extension FTStoreCustomViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let currenSelectedCell = self.collectionView?.cellForItem(at: indexPath) as? FTStoreCustomCollectionCell {
            if let previousSelectedCellIndexPath = self.selectedIndexPath, let previousSelectedCell = self.collectionView?.cellForItem(at: previousSelectedCellIndexPath) as? FTStoreCustomCollectionCell {
                previousSelectedCell.isSelected = false
                currenSelectedCell.isSelected = true
            } else {
                currenSelectedCell.isSelected = true
            }
        }
        let item = viewModel.itemAt(index: indexPath.row)
        if let style = item {
            if sourceType == .none
                , FTStorePremiumPublisher.shared.premiumUser?.nonPremiumQuotaReached ?? false {
                self.delegate?.customController(self, showIAPAlert: nil);
                return;
            }
            let name = "\(style.title)"
            if let fileUrl = FTStoreCustomTemplatesHandler.shared.filUrlForTemplate(template: style) {
            let tempUrl = FTTemplatesCache().temporaryFolder.appendingPathComponent(name).appendingPathExtension(fileUrl.pathExtension)
            do {
                if FileManager.default.fileExists(atPath: tempUrl.path) {
                    try FileManager.default.removeItem(at: tempUrl)
                }
                try FileManager.default.copyItem(at: fileUrl, to: tempUrl)
                let info = sourceType == .shelf ? FTTemplateInfo(url: fileUrl) : FTTemplateInfo(url: tempUrl)
                info.isLandscape = style.orientation == .landscape ? true : false
                info.isCustom = true
                self.delegate?.setCurrentSelectedURL(url: fileUrl)
                self.delegate?.customController(self, didSelectTemplate: info);
            } catch let error {
                UIAlertController.showAlert(withTitle: "templatesStore.alert.error".localized, message: error.localizedDescription, from: self, withCompletionHandler: nil)
            }
        }
            // Track Event
            FTStorePremiumPublisher.shared.actionStream.send(.track(event: EventName.templates_custom_template_tap, params: nil, screenName: ScreenName.templatesStore))
        }

    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columnWidth = columnWidthForSize(self.view.frame.size)
        let size = CGSize(width: columnWidth, height: ((columnWidth)/FTStoreConstants.Template.potraitAspectRation) + FTStoreConstants.Template.extraHeightPadding)
        if let item = viewModel.itemAt(index: indexPath.row) {
            if item.orientation == .landscape {
                return CGSize(width: columnWidth, height: ((columnWidth)/FTStoreConstants.Template.landscapeAspectRatio) + FTStoreConstants.Template.extraHeightPadding)
            } else {
                return CGSize(width: columnWidth, height: ((columnWidth)/FTStoreConstants.Template.potraitAspectRation) + FTStoreConstants.Template.extraHeightPadding)
            }
        }
        return size
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if self.parent is FTStoreContainerViewController {
            return CGSize(width: self.view.frame.size.width, height: 70)
        }
        return CGSize(width: self.view.frame.size.width, height: 20)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: FTStoreConstants.Template.interItemSpacing, bottom: 0, right: FTStoreConstants.Template.interItemSpacing)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let item = viewModel.itemAt(index: indexPath.row) {
            self.selectedFile = self.delegate?.currentSelectedURL()
            if let fileTitle = self.selectedFile?.deletingPathExtension().lastPathComponent, fileTitle == (item).title {
                cell.isSelected = true
                selectedIndexPath = indexPath
            }
        }
    }
}

// MARK: - Observers
private extension FTStoreCustomViewController {
    func observers() {
        importActionObserver()
    }

    func importActionObserver() {
        guard let customTemplateImportManager else { return }

        customTemplateImportManager.actionStream.sink {[weak self] action in
            guard let self = self else { return }
            switch action {
            case .photoLibrary:
                FTPHPicker.shared.presentPhPickerController(from: self, selectionLimit: 1)

            case .takePhoto:
                FTImagePicker.shared.showImagePickerController(from: self)

            case .files:
                if(nil == self.importFileHandler) {
                    self.importFileHandler = FTImportFileHandler(withDelegate: self);
                }
                self.importFileHandler?.importFile(onViewController: self);
            }
        }.store(in: &customTemplateImportManager.cancellables)

        customTemplateImportManager.importConverterOutput.sink {[weak self] action in
            guard let self = self else { return }
            switch action {
            case .importedFileUrl(let url, let error):
                if let url = url {
                    self.presentPreviewVC(imageUrl: url)
                } else if let err = error {
                    UIAlertController.showAlert(withTitle: "templatesStore.alert.error".localized, message: err.localizedDescription, from: self, withCompletionHandler: nil)
                }
            case .createNootbookOutput( _, let error):
                if let err = error  {
                    UIAlertController.showAlert(withTitle: "templatesStore.alert.error".localized, message: err.localizedDescription, from: self, withCompletionHandler: nil)
                }
                self.viewModel.loadTemplates()
            }
        }.store(in: &customTemplateImportManager.cancellables)

    }

    @MainActor
    private func presentPreviewVC(imageUrl: URL) {
        let vc = FTStoreCustomPreviewViewController.controller(fileUrl: imageUrl, actionManager: storeActionManager)
        let navi = UINavigationController(rootViewController: vc)
        navi.modalPresentationStyle = .formSheet
        navi.modalPresentationCapturesStatusBarAppearance = true
        self.present(navi, animated: true)
    }

}

// MARK: - PhotoLibraryDelegates
extension FTStoreCustomViewController: FTPHPickerDelegate, FTImagePickerDelegate {
    public func didFinishPicking(image: UIImage, picker: UIImagePickerController) {
        picker.dismiss(animated: true) { [weak self] in
            self?.customTemplateImportManager?.importConverterInput.send(.generatePDF(images: [image]))
        }
    }

    public func didFinishPicking(results: [PHPickerResult], photoType: PhotoType) {
        FTPHPicker.shared.processResultForUIImages(results: results) { [weak self] phItems in
            if let phItem = phItems.first {
                self?.customTemplateImportManager?.importConverterInput.send(.generatePDF(images: [phItem.image]))
            }
        }
    }
}

extension FTStoreCustomViewController : FTImportFileHandlerDelegate {
    func importFileHandler(_ handler: FTImportFileHandler, didFinishingPickingURL urls: [URL]) {
            if let url = urls.first {
                customTemplateImportManager?.importConverterInput.send(.convertToPDF(filePath: url.path))
        }
    }

}


// MARK: - contextMenuConfiguration
extension FTStoreCustomViewController {

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let sectionType = viewModel.dataSource.snapshot().sectionIdentifiers[indexPath.section]
        if sectionType == .noRecords {
            return nil
        }
        self.delegate?.customController(self, menuShown: true)
        let identifier = indexPath as NSIndexPath
        return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil) { _ in
            let delete = UIAction(title: "templatesStore.custom.alert.remove".localized, image: UIImage(systemName: "trash")) { [weak self] _ in
                Task {
                    if let item = self?.viewModel.itemAt(index: indexPath.row) {
                        do {
                            try await FTStoreCustomTemplatesHandler.shared.removeFile(item: item)
                            self?.viewModel.loadTemplates()
                        } catch {
                            UIAlertController.showAlert(withTitle: "templatesStore.alert.error".localized, message: error.localizedDescription, from: self, withCompletionHandler: nil)
                        }
                    }
                }
            }
            delete.attributes = .destructive
            return UIMenu(title: "", children: [delete])
        }
    }

    func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? IndexPath,
              let cell = collectionView.cellForItem(at: identifier) as? FTStoreCustomCollectionCell else {
            return nil
        }
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        return UITargetedPreview(view: cell.thumbnail!, parameters: parameters)
    }

    func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        self.delegate?.customController(self, menuShown: false)
        guard let identifier = configuration.identifier as? IndexPath,
              let cell = collectionView.cellForItem(at: identifier) as? FTStoreCustomCollectionCell else {
            return nil
        }
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        return UITargetedPreview(view: cell, parameters: parameters)
    }
}
