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
}

class FTStoreCustomViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!

    weak var delegate: FTStoreCustomDelegate?;
    var selectedFile: URL?
    var sourceType: Source = .none
    private var selectedIndexPath: IndexPath?

    private var customTemplateImportManager = FTCustomTemplateImportManager.shared
    private var headerView: FTLibraryHeaderView? = nil
    private var importFileHandler : FTImportFileHandler?
    private var currentSize: CGSize = .zero
    let viewModel = FTStoreCustomTemplateViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        observers()
        initializeCollectionView()
        if sourceType != .none {
            self.view.backgroundColor = UIColor.appColor(.panelBgColor)
            self.collectionView.backgroundColor = UIColor.appColor(.panelBgColor)
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
            if item is FTStoreCustomType {
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FTStoreLibraryEmptyCollectionCell.reuseIdentifier, for: indexPath) as? FTStoreLibraryEmptyCollectionCell else {
                    fatalError("can't dequeue FTStoreLibraryEmptyCollectionCell")
                }
                return cell
            }
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
                , FTStoreContainerHandler.shared.premiumUser?.nonPremiumQuotaReached ?? false {
                self.delegate?.customController(self, showIAPAlert: nil);
                return;
            }
            let name = "\(style.title)"
            let fileUrl = FTStoreCustomTemplatesHandler.shared.pdfUrlForTemplate(template: style)
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

    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sectionType = viewModel.dataSource.snapshot().sectionIdentifiers[indexPath.section]
        if sectionType == .noRecords {
            return CGSize(width: collectionView.frame.size.width, height: collectionView.frame.size.height - 150)
        }
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
            case .createNootbookOutput(let url, let error):
                if let err = error  {
                    UIAlertController.showAlert(withTitle: "templatesStore.alert.error".localized, message: err.localizedDescription, from: self, withCompletionHandler: nil)
                }
                self.viewModel.loadTemplates()
            }
        }.store(in: &customTemplateImportManager.cancellables)

    }

    @MainActor
    private func presentPreviewVC(imageUrl: URL) {
        if let vc = UIStoryboard.init(name: "FTTemplatesStore", bundle: storeBundle).instantiateViewController(withIdentifier: "FTStoreCustomPreviewViewController") as? FTStoreCustomPreviewViewController {
            let navi = UINavigationController(rootViewController: vc)
            vc.fileUrl = imageUrl
            navi.modalPresentationStyle = .formSheet
            navi.modalPresentationCapturesStatusBarAppearance = true
            self.present(navi, animated: true)
        }
    }

}

// MARK: - PhotoLibraryDelegates
extension FTStoreCustomViewController: FTPHPickerDelegate, FTImagePickerDelegate {
    public func didFinishPicking(image: UIImage, picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            FTCustomTemplateImportManager.shared.importConverterInput.send(.generatePDF(images: [image]))
        }
    }

    public func didFinishPicking(results: [PHPickerResult], photoType: PhotoType) {
        FTPHPicker.shared.processResultForUIImages(results: results) { phItems in
            if let phItem = phItems.first {
                FTCustomTemplateImportManager.shared.importConverterInput.send(.generatePDF(images: [phItem.image]))
            }
        }
    }
}

extension FTStoreCustomViewController : FTImportFileHandlerDelegate {
    func importFileHandler(_ handler: FTImportFileHandler, didFinishingPickingURL urls: [URL]) {
            if let url = urls.first {
            FTCustomTemplateImportManager.shared.importConverterInput.send(.convertToPDF(filePath: url.path))
        }
    }

}
