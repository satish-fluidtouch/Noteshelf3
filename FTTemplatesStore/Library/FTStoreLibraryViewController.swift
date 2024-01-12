//
//  FTStoreLibraryViewController.swift
//  TempletesStore
//
//  Created by Siva on 21/02/23.
//

import UIKit
import FTCommon
import Combine

public enum Source {
    case none
    case shelf
    case addMenu
    case finder
    case settings
    case changeTemplate
}

public class FTTemplateInfo: NSObject {
    public var url: URL?
    public var isLandscape: Bool = false;
    public var isDark: Bool = false;
    public var isCustom: Bool = false;

    init(url inURL: URL) {
        url = inURL;
    }
    
    override init() {
        
    }
}

public class FTDairyTemplateInfo: FTTemplateInfo {
    public let startDate: Date;
    public let endDate: Date;
    public var themeName: String;
    public var coverImage: UIImage?;
    public var title: String?;
    
    init(startDate stDate: Date
         ,endDate edDate: Date
         ,themeName thName: String) {
        startDate = stDate;
        endDate = edDate;
        themeName = thName
        super.init()
    }
}

public protocol FTStoreLibraryDelegate:NSObjectProtocol, FTThemeUpdateURL {
    func libraryController(_ contmroller: UIViewController,didSelectTemplate info: FTTemplateInfo);
    func libraryController(_ contmroller: UIViewController,showIAPAlert feature: String?);
    func libraryController(_ contmroller: UIViewController,menuShown isMenuShown: Bool);
}

class FTStoreLibraryViewController: UIViewController {
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private var emptyView: UIView!

    private weak var delegate: FTStoreLibraryDelegate?;
    private let viewModel = FTStoreLibraryViewModel()
    private var headerView: FTLibraryHeaderView? = nil

    private var currentSize: CGSize = .zero
    private var contextMenuSelectedIndexPath: IndexPath?
    private var sourceType: Source = .none
    private var selectedStyle: FTTemplateStyle?
    private var selectedFile: URL?

    private var selectedIndexPath: IndexPath?
    
    static func controller(source: Source,
                           delegate: FTStoreLibraryDelegate,
                           selectedFile: URL?) -> FTStoreLibraryViewController  {
        let storyboard = UIStoryboard(name: "FTTemplatesStore", bundle: storeBundle)
        let viewController = storyboard.instantiateViewController(withIdentifier: "FTStoreLibraryViewController") as! FTStoreLibraryViewController
        viewController.sourceType = source
        viewController.delegate = delegate;
        viewController.selectedFile = selectedFile
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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
        viewModel.loadLibraryTemplates()
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

    private func columnWidthForSize(_ size: CGSize) -> CGFloat {
        let noOfColumns = self.noOfColumnsForCollectionViewGrid()
        let totalSpacing = FTStoreConstants.Template.interItemSpacing * CGFloat(noOfColumns - 1)
        let itemWidth = (size.width - totalSpacing - (FTStoreConstants.Template.gridHorizontalPadding * 2)) / CGFloat(noOfColumns)
        return itemWidth
    }

    func reloadData() {
        if let pare = self.parent as? FTStoreContainerViewController {
            if let seg = pare.topSegmentView, pare.segmentControl.selectedIndex == 1 {
                headerView?.addSubview(seg)
            }
        }
    }

    func initializeCollectionView() {
        self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        let alignedFlowLayout = FTTagsAlignedCollectionViewFlowLayout(verticalAlignment: .bottom)
        self.collectionView.collectionViewLayout = alignedFlowLayout
        collectionView.allowsMultipleSelection = false
        self.collectionView.delegate = self
        self.configureDatasource()
    }

    func configureDatasource() {
        viewModel.dataSource = StoreLibraryDatasource(collectionView: self.collectionView, cellProvider: {[weak self] collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FTStoreLibraryCollectionCell.reuseIdentifier, for: indexPath) as? FTStoreLibraryCollectionCell else {
                fatalError("can't dequeue FTStoreLibraryCollectionCell")
            }
            
            cell.prepareCellWith(style: item as! FTTemplateStyle, sourceType: self?.sourceType ?? .none)
            if self?.sourceType == .settings || self?.sourceType == .shelf || self?.sourceType == .changeTemplate, let style = item as? FTTemplateStyle, (style.type == FTDiscoveryItemType.diary.rawValue || style.type == FTDiscoveryItemType.userJournals.rawValue) {
                cell.thumbnail?.alpha = 0.2
            } else {
                cell.thumbnail?.alpha = 1
            }
            return cell
        })

        viewModel.dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self = self else { return nil }
            self.headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FTLibraryHeaderView", for: indexPath) as? FTLibraryHeaderView
            // Configure the header view with data from the data source
            if let pare = self.parent as? FTStoreContainerViewController {
                if let seg = pare.topSegmentView, pare.segmentControl.selectedIndex == 1 {
                    self.headerView?.addSubview(seg)
                }
            }
            return self.headerView
        }
    }

    func presentDatePicker() {
        if let style = selectedStyle {
            let templateInfo = DiscoveryItem(displayTitle: style.title, fileName: style.templateName, displaySubTitle: "", type: FTDiscoveryItemType.diary.rawValue)
            FTDairyDateSelectionPicker_iOS.presentDatePicker(template: templateInfo, delegate: self, onViewController: self);
        }
    }

}
// MARK: - UICollectionViewDelegate
extension FTStoreLibraryViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if let _ = self.parent as? FTStoreContainerViewController {
            return CGSize(width: self.view.frame.size.width, height: 70)
        }
        return CGSize(width: self.view.frame.size.width, height: 20)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let currenSelectedCell = self.collectionView?.cellForItem(at: indexPath) as? FTStoreLibraryCollectionCell {
            if let previousSelectedCellIndexPath = self.selectedIndexPath, let previousSelectedCell = self.collectionView?.cellForItem(at: previousSelectedCellIndexPath) as? FTStoreLibraryCollectionCell {
                previousSelectedCell.isSelected = false
                currenSelectedCell.isSelected = true
            } else {
                currenSelectedCell.isSelected = true
            }
        }
        let item = viewModel.itemAt(index: indexPath.row)
        if let style = item {
            selectedStyle = style
            if style.type == FTDiscoveryItemType.diary.rawValue {
                if let premiumUser = FTStorePremiumPublisher.shared.premiumUser,premiumUser.isPremiumUser {
                    presentDatePicker()
                }
                else {
                    self.delegate?.libraryController(self, showIAPAlert: "Digital Diary");
                }
                return;
            }
            if sourceType == .none, FTStorePremiumPublisher.shared.premiumUser?.nonPremiumQuotaReached ?? false {
                self.delegate?.libraryController(self, showIAPAlert: nil);
                return;
            }

            func createNotebookFor(fileUrl: URL, fileName: String) {
                let name = "\(fileName)"
                let tempUrl = FTTemplatesCache().temporaryFolder.appendingPathComponent(name).appendingPathExtension(fileUrl.pathExtension)
                do {
                    if FileManager.default.fileExists(atPath: tempUrl.path) {
                        try FileManager.default.removeItem(at: tempUrl)
                    }
                    try FileManager.default.copyItem(at: fileUrl, to: tempUrl)
                    let isDark = style.templateName.lowercased().contains("dark") ? true : false
                    let isLandscape = style.orientation == .landscape ? true : false


                    let info = sourceType == .shelf ? FTTemplateInfo(url: fileUrl) : FTTemplateInfo(url: tempUrl)
                    info.isLandscape = isLandscape;
                    info.isDark = isDark;
                    self.delegate?.setCurrentSelectedURL(url: fileUrl)
                    self.delegate?.libraryController(self, didSelectTemplate: info);
                } catch let error {
                    UIAlertController.showAlert(withTitle: "templatesStore.alert.error".localized, message: error.localizedDescription, from: self, withCompletionHandler: nil)
                }
            }
            if style.type == FTDiscoveryItemType.userJournals.rawValue {
                let storeServiceApi = FTStoreService()
                Task {
                    if let downloadUrl = style.inspirationsUrl, let fileName = style.fileName {
                        self.showingLoadingindicator()
                        let fileUrl = try await storeServiceApi.downloadinspirationJournalFor(url: downloadUrl, fileName: fileName)
                        self.hideLoadingindicator()
                        createNotebookFor(fileUrl: fileUrl.appendingPathComponent(fileName).appendingPathExtension("pdf"), fileName: style.title)
                    }
                }
            } else {
                let fileUrl = style.pdfPath()
                createNotebookFor(fileUrl: fileUrl, fileName: style.title)
            }
            // Track Event
            FTStorePremiumPublisher.shared.actionStream.send(.track(event: EventName.templates_library_template_tap, params: nil, screenName: ScreenName.templatesStore))
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let item = viewModel.itemAt(index: indexPath.row)
        if let style = item, sourceType == .settings || sourceType == .changeTemplate || sourceType == .shelf, (style.type == FTDiscoveryItemType.diary.rawValue || style.type == FTDiscoveryItemType.userJournals.rawValue) {
            return false
        }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let item = viewModel.itemAt(index: indexPath.row) {
            cell.isSelected = false
            self.selectedFile = self.delegate?.currentSelectedURL()
            if let selectedFileName = self.selectedFile?.lastPathComponent.deletingPathExtension {
                let fileName = item.templateName
                let wordsArray = selectedFileName.components(separatedBy: "_")
                var modifiedArray = wordsArray
                var orientation = ThumbnailOrientation.potrait
                orientation = modifiedArray.last == "land" ? .landscape : .potrait
                modifiedArray.removeLast()
                let resultString = modifiedArray.joined(separator: "_")
                if resultString == fileName, item.orientation == orientation {
                    cell.isSelected = true
                    selectedIndexPath = indexPath
                }
            }
        }
    }

 
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sectionType = viewModel.dataSource.snapshot().sectionIdentifiers[indexPath.section]
        let item = viewModel.itemAt(index: indexPath.row)

        let columnWidth = columnWidthForSize(self.view.frame.size)
        let size = CGSize(width: columnWidth, height: ((columnWidth)/FTStoreConstants.Template.potraitAspectRation) + FTStoreConstants.Template.extraHeightPadding)
        if let fileUrl = item?.thumbnailPath() {
            let image = UIImage(contentsOfFile: fileUrl.path)
            if let image {
                if  image.size.width > image.size.height  { // landscape
                    return CGSize(width: columnWidth, height: ((columnWidth)/FTStoreConstants.Template.landscapeAspectRatio) + FTStoreConstants.Template.extraHeightPadding)
                } else {
                    return CGSize(width: columnWidth, height: ((columnWidth)/FTStoreConstants.Template.potraitAspectRation) + FTStoreConstants.Template.extraHeightPadding)
                }
            }
        }

        return size
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: FTStoreConstants.Template.interItemSpacing, bottom: 0, right: FTStoreConstants.Template.interItemSpacing)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 32.0
    }
}

extension FTStoreLibraryViewController: FTDairyDateSelectionPickerDelegate {
    func onDatesSelected(_ generatorController: FTDairyDateSelectionPickerController, startDate: Date, endDate: Date) {
        if let style = self.selectedStyle {
            let isLandscape = style.orientation == .landscape ? true : false
            if let thumbnailUrl = style.thumbnailUrl {
                URLSession.shared.dataTask(with: thumbnailUrl) { [weak self] (data, response, error) in
                    guard let self = self else {
                        return
                    }
                    if let error = error {
                        print("Error fetching image: \(error)")
                    } else if let data = data, let image = UIImage(data: data) {
                        // Update the UI on the main thread
                        DispatchQueue.main.async {
                            let info = FTDairyTemplateInfo(startDate: startDate, endDate: endDate, themeName: style.templateName);
                            info.title = style.title;
                            info.isLandscape = isLandscape;
                            info.coverImage = image;

                            self.delegate?.libraryController(self, didSelectTemplate: info);
                        }
                    }
                }.resume()
            }
        }
    }
}

// MARK: - contextMenuConfiguration
extension FTStoreLibraryViewController {

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let sectionType = viewModel.dataSource.snapshot().sectionIdentifiers[indexPath.section]
        if sectionType == .noRecords {
            return nil
        }
        self.delegate?.libraryController(self, menuShown: true)
        let identifier = indexPath as NSIndexPath
        contextMenuSelectedIndexPath = indexPath as IndexPath
        return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil) { _ in
            let delete = UIAction(title: "librarystore.removefromLibrary".localized, image: UIImage(systemName: "trash")) { [weak self] _ in
                Task {
                    if let item = self?.viewModel.itemAt(index: indexPath.row) {
                        do {
                            try await FTStoreLibraryHandler.shared.removeFromLibrary(template: item)
                            self?.viewModel.loadLibraryTemplates()
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
              let cell = collectionView.cellForItem(at: identifier) as? FTStoreLibraryCollectionCell else {
            return nil
        }
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        return UITargetedPreview(view: cell.thumbnail!, parameters: parameters)
    }

    func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        self.delegate?.libraryController(self, menuShown: false)
        guard let identifier = configuration.identifier as? IndexPath,
              let cell = collectionView.cellForItem(at: identifier) as? FTStoreLibraryCollectionCell else {
            return nil
        }
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        return UITargetedPreview(view: cell, parameters: parameters)
    }
}
