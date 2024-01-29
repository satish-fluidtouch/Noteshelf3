//
//  FTMediaViewController.swift
//  Noteshelf3
//
//  Created by Sameer on 21/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit
import FTCommon

extension Notification.Name {
    static let didRemoveMedia = Notification.Name(rawValue: "FTDidRemoveMedia")
    static let didUpdateMedia = Notification.Name(rawValue: "FTDidUpdateMedia")
    static let didAddMedia = Notification.Name(rawValue: "FTDidAddMedia")
}

protocol FTMediaDelegate: AnyObject {
    func  didTapMoreOption(cell: UICollectionViewCell, item: FTMediaItem?)
}

class FTMediaDocumentPage {
    var pageId: String = ""
    var mediaObjects: [FTMediaObject] = []
    
    init(pageId: String, mediaObjects: [FTMediaObject]) {
        self.pageId = pageId
        self.mediaObjects = mediaObjects
    }
}

fileprivate typealias MediaDataSource = UICollectionViewDiffableDataSource<Int, AnyHashable>
fileprivate typealias MediaSnapShot = NSDiffableDataSourceSnapshot<Int, AnyHashable>

struct FTMediaSection: Hashable {
    var name:String
}

class FTMediaViewController: UIViewController, FTFinderTabBarProtocol {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var noMediaView: UIView!
    @IBOutlet weak var dividerView: UIView!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var compactEditButton: UIButton?
    @IBOutlet weak var titleLabel: FTCustomLabel!
    @IBOutlet weak var headerView: UIView!
    fileprivate var dataSource : MediaDataSource! //Used for UI Diffable datasource
    fileprivate var snapShot = MediaSnapShot()
    @IBOutlet weak var noMediaDescription: FTCustomLabel!
    @IBOutlet weak var noMediaTitle: FTCustomLabel!
    @IBOutlet weak var primaryButton: UIButton!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    private lazy var layout = FTCollectionViewWaterfallLayout()
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var expandButton: UIButton!
    var documentPages = [FTMediaDocumentPage]()
    weak var delegate: FTFinderTabBarController?
    var screenMode: FTFinderScreenMode {
        return self.delegate?.currentScreenMode() ?? .normal
    }
    weak var document:FTThumbnailableCollection?;
    var mediaObjects = [FTMediaObject]()
    var selectedTab: FTFinderSelectedTab = .content
    
    var selectedMediaType: FTMediaType {
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "mediaType")
            UserDefaults.standard.synchronize()
        }
        
        get {
            let value = UserDefaults.standard.object(forKey: "mediaType") as? String
            return FTMediaType(rawValue: value ?? "") ?? .allMedia
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        #if targetEnvironment(macCatalyst)
            dividerView.isHidden = true
            contentView.isHidden = true
            layout.columnCount = 2
            collectionView.contentInset = UIEdgeInsets(top: 44, left: 0, bottom: 80, right: 0)
            collectionView.contentInsetAdjustmentBehavior = .never
        #else
            layout.columnCount = (screenMode == .fullScreen) ? 4 : 2
            confiureUI()
            updateContentInsets()
        #endif
        collectionView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialSetup()
        configureDiffableDataSource()
        createAndApplySnapshot()
        showPlaceHolderView(true)
        self.setUpData()
        NotificationCenter.default.addObserver(self, selector: #selector(didRemoveMedia(_:)), name: .didRemoveMedia, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didAddMedia(_:)), name: .didAddMedia, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateMedia(_:)), name: .didUpdateMedia, object: nil)
        contentView.addVisualEffectBlur(cornerRadius: 0)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        #if !targetEnvironment(macCatalyst)
        configureNavigation(title: "shelf.sidebar.content".localized)
        #endif
        self.navigationController?.navigationBar.isHidden = (screenMode == .normal)
    }
    
    internal func snapshotItem(for indexPath: IndexPath) -> AnyHashable {
        let sectionType = dataSource.snapshot().sectionIdentifiers[indexPath.section]
        return dataSource.snapshot().itemIdentifiers(inSection: sectionType)[indexPath.row]
    }
    
    private func configureDiffableDataSource() {
        dataSource = MediaDataSource(collectionView: self.collectionView, cellProvider: { [weak self] (collectionView, indexPath, item) -> UICollectionViewCell? in
            guard let self = self else {
                return nil
            }
            self.showPlaceHolderView(true)
            if let mediaObject =  item as? FTMediaObject {
                var cell = self.collectionView(collectionView, normalCellForItemAt: indexPath, mediaObject: mediaObject)
                if mediaObject.mediaType == .audio {
                    cell = self.collectionView(collectionView, audioCellForItemAt: indexPath, mediaObject: mediaObject)
                }
                self.showPlaceHolderView(false)
                return cell
            }
            return nil
        })
    }
    
    private func createAndApplySnapshot() {
        guard self.dataSource != nil else { return }
        self.snapShot.appendSections([0])
        self.snapShot.appendItems(self.mediaObjects, toSection: 0)
        self.dataSource.apply(self.snapShot, animatingDifferences: true)
    }
    
    private func updateSourceFor(page: FTMediaDocumentPage) {
        let filteredObjects = objectsToLoad(items: page.mediaObjects)
        let mappedObjects = filteredObjects.map { eachObject in
            return eachObject
        }
        var snapShot = self.dataSource.snapshot()
        snapShot.appendItems(mappedObjects)
        self.dataSource.apply(snapShot)
    }
    
    private func objectsToLoad(items: [FTMediaObject]) -> [FTMediaObject] {
        var itemsToReturn = [FTMediaObject]()
        let selectedMedia = currentSelectedMedia()
        for eachObj in items {
            if selectedMedia == FTMediaType.allMedia {
                itemsToReturn.append(eachObj)
            } else if eachObj.mediaType == selectedMedia {
                itemsToReturn.append(eachObj)
            }
        }
        return itemsToReturn
    }
    
    @objc private func didAddMedia(_ notification: Notification) {
        if let userInfo = notification.userInfo, let noteshelfPage = userInfo["page"] as? FTNoteshelfPage, let annotations = userInfo["annotations"] as? [FTAnnotation] {
            let page = documentPages.filter { eachPage in
                return eachPage.pageId == noteshelfPage.uuid
            }
            annotations.forEach { eachAnnotation in
                if eachAnnotation.isMediaType {
                    if  !page.isEmpty, let documentPage = page.first {
                        let mediaObject = FTMediaObject(page: noteshelfPage, annotation: eachAnnotation)
                        self.mediaObjects.append(mediaObject)
                        documentPage.mediaObjects.append(mediaObject)
                        let filteredObjects = objectsToLoad(items: documentPage.mediaObjects)
                        var snapShot = self.dataSource.snapshot()
                        snapShot.appendItems(filteredObjects)
                        self.dataSource.apply(snapShot)
                    } else {
                        self.createAndUpdatePages(doc: noteshelfPage, annotations: [eachAnnotation])
                    }
                }
            }
        }
    }

    @objc private func didRemoveMedia(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let currentPage = userInfo["page"] as? FTNoteshelfPage, let annotations = userInfo["annotations"] as? [FTAnnotation] else {
            return
        }
        let matchingPages = documentPages.filter { $0.pageId == currentPage.uuid }
        annotations.forEach { eachAnnotation in
            guard  let documentPage = matchingPages.first, eachAnnotation.isMediaType, let item = documentPage.mediaObjects.first(where: { $0.annotation == eachAnnotation }) else {
                return
            }
            if let index = documentPage.mediaObjects.firstIndex(of: item) {
                documentPage.mediaObjects.remove(at: index)
            }
            if let index = mediaObjects.firstIndex(of: item) {
                mediaObjects.remove(at: index)
            }
            var snapShot = dataSource.snapshot()
            snapShot.deleteItems([item])
            dataSource.apply(snapShot)
            showPlaceHolderView(mediaObjects.isEmpty)
        }
    }
    
    @objc private func didUpdateMedia(_ notification: Notification) {
        if let userInfo = notification.userInfo, let annotation = userInfo["annotation"] as? FTAnnotation, annotation.isMediaType {
            var snapShot = self.dataSource.snapshot()
            let item = snapShot.itemIdentifiers.first(where: { eachItem in
                if let newItem = eachItem as? FTMediaObject, newItem.annotation == annotation {
                    return true
                } else {
                    return false
                }
            })
            if let item {
                snapShot.reloadItems([item])
                self.dataSource.apply(snapShot)
            }
        }
    }
   
    
    private func configureNavigation(hideBackButton: Bool = false, title: String, preferLargeTitle: Bool = true) {
        self.navigationItem.hidesBackButton = true
        self.navigationController?.navigationItem.hidesBackButton = true
        self.navigationItem.title = ""
        setUpBarButtons()
        self.navigationItem.title = title
        if self.delegate?._isRegularClass() ?? false {
            self.navigationController?.additionalSafeAreaInsets = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        }
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font:  UIFont.clearFaceFont(for: .medium, with: 20)]
        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.font: UIFont.clearFaceFont(for: .medium, with: 36)]
        self.navigationController?.navigationBar.layoutMargins.left = 44
        self.navigationController?.navigationBar.prefersLargeTitles = preferLargeTitle
        self.navigationController?.navigationItem.largeTitleDisplayMode = .always
   }
    
    private func setUpBarButtons() {
        let attributes = [NSAttributedString.Key.font: UIFont.appFont(for: .regular, with: 17), NSAttributedString.Key.foregroundColor: UIColor.appColor(.accent)]
        let collapseBarButton = UIBarButtonItem(image: UIImage.image(for: "arrow.down.right.and.arrow.up.left", font: UIFont.appFont(for: .semibold, with: 14)), style: .plain, target: self, action: #selector(collpaseButtonAction(_ :)))
        let editBarButton = UIBarButtonItem(image: UIImage.image(for: "line.3.horizontal.decrease.circle", font: UIFont.systemFont(ofSize: 14, weight: .medium)), style: .plain, target: self, action: nil)
        editBarButton.menu = menuItems()
        let closeBarButton = UIBarButtonItem(title: NSLocalizedString("Close", comment: "Close"), style: .plain, target: self, action: #selector(closeButtonAction(_ :)))
        closeBarButton.setTitleTextAttributes(attributes, for: .normal)
        if self.delegate?._isRegularClass() ?? false {
            let spacer1 = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            spacer1.width = 10
            let spacer2 = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            spacer2.width = 14
            self.navigationItem.rightBarButtonItems = [closeBarButton, spacer2, collapseBarButton, spacer1, editBarButton]
            navigationItem.leftBarButtonItems = []
        } else {
             self.navigationItem.rightBarButtonItems = []
         }
    }
    
    @objc func collpaseButtonAction(_ sender : UIButton) {
        self.navigationItem.title = ""
        let coulumnCount = (self.screenMode == .fullScreen) ? 2 : 4
        UIView.animate(withDuration: 0.4, delay: 0) {
            self.layout.columnCount = coulumnCount
        }
        self.delegate?.shouldStartWithFullScreen(false)
        self.delegate?.didTapOnExpandButton()
    }
    
    @objc func closeButtonAction(_ sender : UIButton) {
        self.delegate?.didTapOnCloseButton()
    }

    func showPlaceHolderView(_ show: Bool) {
        self.collectionView.isHidden = show
        self.noMediaView.isHidden = !show
    }
    
    private func configureEditButton() {
        editButton.menu =  menuItems()
        compactEditButton?.menu = menuItems()
        editButton.showsMenuAsPrimaryAction = true
        compactEditButton?.showsMenuAsPrimaryAction = true
    }
    
    private func menuItems() -> UIMenu {
        let moreOptions: [FTMediaType] = [.allMedia, .audio, .photo, .sticker, .webclip]
        var mediaActions = [UIAction]()
        var otherAction = [UIAction]()
        var actions = [UIMenuElement]()
        moreOptions.forEach { eachType in
            let action = eachType.actionElment {[weak self] action in
                self?.didTapEditOption(identifier: action.identifier.rawValue)
            }
            if let mediaType = FTMediaType(rawValue: action.identifier.rawValue), self.selectedMediaType == mediaType {
                action.state = .on
            }
            mediaActions.append(action)
        }
        
        let fullScreenAction = UIAction(title: NSLocalizedString("finder.fullscreen", comment: "Full Screen"), image: UIImage(systemName: "rectangle.inset.filled", withConfiguration: UIImage.SymbolConfiguration(font: UIFont.appFont(for: .regular, with: 15))),identifier: nil) {[weak self] action in
            self?.delegate?.didTapOnExpandButton()
        }
        otherAction.append(fullScreenAction)
        actions.append(UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: mediaActions))
        if self.screenMode == .normal && (self.delegate?._isRegularClass() ?? false) {
            actions.append(UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: otherAction))
        }
        return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: actions)
    }
    
    private func didTapEditOption(identifier: String) {
        if let option = FTMediaType(rawValue: identifier) {
            self.selectedMediaType = option
            FTFinderEventTracker.trackFinderEvent(with: "finder_more_filter_tap", params: ["filter": option.eventDescription()])
            updateAndReloadCollectionView()
            if let optionsMenu = editButton.menu?.children.first as? UIMenu {
                let elements = optionsMenu.children
                for eachElement in elements {
                    if let action = eachElement as? UIAction{
                        if action.identifier.rawValue == identifier {
                            action.state = .on
                        } else {
                            action.state = .off
                        }
                    }
                }
            }
         }
    }
    
    func resetSelection() {
        
    }
    
    func screenModeDidChange() {
        if screenMode == .normal {
//            contentView.isHidden = false
//            dividerView.isHidden = true
//            self.navigationController?.navigationBar.isHidden = true
        }
    }
    
    private func updateMenuItemsIfNeeded() {
        
    }
    
    @IBAction func didTapOnDismiss(_ sender: Any) {
        self.delegate?.didTapOnDismissButton()
    }
    
    @IBAction func didTapPrimaryButton(_ sender: Any) {
        self.delegate?.didTapOnPrimaryButton()
    }
    
    private func confiureUI() {
        expandButton.isHidden = !(self.delegate?._isRegularClass() ?? false)
        editButton.isHidden = !(self.delegate?._isRegularClass() ?? false)
        primaryButton.isHidden = !(self.delegate?._isRegularClass() ?? false)
        dismissButton.isHidden = self.delegate?._isRegularClass() ?? false
        compactEditButton?.isHidden = self.delegate?._isRegularClass() ?? false
        titleLabel.text = "finder.tabbar.content".localized
        configureEditButton()
        dividerView.isHidden = true
        contentView.isHidden = (screenMode == .fullScreen)
    }
    
    func didChangeState(to screenState: FTFinderScreenState) {
        if screenState == .fullScreen {
            contentView.isHidden = true
            self.layout.columnCount = 4
        } else if screenState == .initial {
            contentView.isHidden = false
            self.layout.columnCount = 2
        }
    }
    
    private func initialSetup() {
        collectionView.delegate = self
        layout.minimumColumnSpacing = 2.0
        layout.minimumInteritemSpacing = 2.0
        layout.columnCount = (screenMode == .fullScreen) ? 4 : 2
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.alwaysBounceVertical = true
        self.collectionView.collectionViewLayout  = layout
        updateContentInsets()
        noMediaTitle.text = "finder.media".localized
        noMediaTitle.font = UIFont.clearFaceFont(for: .medium, with: 22)
        noMediaDescription.text = "finder.media.nocontent".localized
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return self.tabBarController?.prefersHomeIndicatorAutoHidden ?? super.prefersHomeIndicatorAutoHidden
    }
    
    override var prefersStatusBarHidden: Bool {
        return self.tabBarController?.prefersStatusBarHidden ?? super.prefersStatusBarHidden
    }

    private func updateContentInsets() {
        if self.screenMode == .fullScreen {
            self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
        } else if self.screenMode == .normal {
            collectionView.contentInset = UIEdgeInsets(top: 108, left: 0, bottom: 80, right: 0)
        }
        collectionView.contentInsetAdjustmentBehavior = (screenMode == .normal) ? .never : .automatic
    }
    
    func configureData(forDocument document: FTThumbnailableCollection, exportInfo: FTExportTarget?, delegate: FTFinderTabBarController?, searchOptions: FTFinderSearchOptions) {
        self.delegate = delegate
        self.document = document
    }
    
    private func allDocumentPages() -> [FTThumbnailable] {
        return self.document?.documentPages() ?? [FTThumbnailable]();
    }
    
    private func setUpData() {
        DispatchQueue.global().async {[weak self] in
            guard let self = self else {
                return
            }
            let pages = self.allDocumentPages()
            self.mediaObjects.removeAll()
            pages.forEach { eachPage in
                if let page = eachPage as? FTNoteshelfPage {
                    let eachPageAnnotations = page.annotationsWithMediaResources()
                    runInMainThread {
                        self.createAndUpdatePages(doc: page, annotations: eachPageAnnotations)
                    }
                }
            }
        }
    }
    
    func createAndUpdatePages(doc: FTNoteshelfPage, annotations: [FTAnnotation]) {
        var arrayToAppend = [FTMediaObject]()
        annotations.forEach { eachAnnotation in
            let mediaObject = FTMediaObject(page: doc, annotation: eachAnnotation)
            arrayToAppend.append(mediaObject)
        }
        if !arrayToAppend.isEmpty {
            self.mediaObjects.append(contentsOf: arrayToAppend)
            let page = FTMediaDocumentPage(pageId: doc.uuid, mediaObjects: arrayToAppend)
            self.documentPages.append(page)
            self.updateSourceFor(page: page)
        }
    }

    private func updateAndReloadCollectionView() {
        let filteredMediaObjects = objectsToLoad(items: self.mediaObjects)
        var newSnapshot = MediaSnapShot()
        newSnapshot.appendSections([0])
        newSnapshot.appendItems(filteredMediaObjects)
        self.dataSource.apply(newSnapshot)
        showPlaceHolderView(filteredMediaObjects.isEmpty)
    }
    
    private func currentSelectedMedia() -> FTMediaType {
        let value = UserDefaults.standard.object(forKey: "mediaType") as? String
        return FTMediaType(rawValue: value ?? "") ?? .allMedia
    }
    
    @IBAction func didTapExpandButton(_ sender: Any) {
        self.delegate?.didTapOnFinderCloseButton()
    }
    
    @IBAction func didTapFilterButton(_ sender: Any) {

    }
    
    func didGoToAudioRecordings(with annotation: FTAnnotation) {
        
    }
}

extension FTMediaViewController:  UICollectionViewDelegate, FTCollectionViewDelegateWaterfallLayout {
    func collectionView(_ collectionView: UICollectionView, normalCellForItemAt indexPath: IndexPath, mediaObject: FTMediaObject) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTMediaCollectionViewCell", for: indexPath)
        if let cell = cell as? FTMediaCollectionViewCell {
            cell.configureCell(mediaObject, index: indexPath.row + 1, delegate: self)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, audioCellForItemAt indexPath: IndexPath, mediaObject: FTMediaObject) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTAudioCollectionCell", for: indexPath)
        if let cell = cell as? FTAudioCollectionCell {
            if screenMode == .fullScreen {
                let image =  cell.volumeImage.image?.withConfiguration(UIImage.SymbolConfiguration(font: UIFont.appFont(for: .regular, with: 32)))
                cell.audioDuration?.font = UIFont.appFont(for: .medium, with: 13)
                cell.volumeImage.image = image
            } else {
                let image =  cell.volumeImage.image?.withConfiguration(UIImage.SymbolConfiguration(font: UIFont.appFont(for: .regular, with: 20)))
                cell.volumeImage.image = image
                cell.audioDuration?.font = UIFont.appFont(for: .medium, with: 10)
            }
            cell.configureCell(mediaObject, index: indexPath.row + 1, delegate: self)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let mediaObject = snapshotItem(for: indexPath) as? FTMediaObject {
            let indexSelected: Int;
            if let index = self.allDocumentPages().firstIndex(where: {$0.uuid == mediaObject.page?.uuid}) {
                indexSelected = index;
            }
            else {
                indexSelected = 0;
            }
            let param =  (self.selectedMediaType == .allMedia) ? "off" : "on"
            track("finder_content_item_tap", params: ["filter_toggle": param],screenName: FTScreenNames.finder)
            self.delegate?.finderViewController(didSelectPageAtIndex: indexSelected)
        }
    }
        
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 186, height: 186)
    }
}

extension FTMediaViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !scrollView.isDragging {
            return
        }
        self.showBottomDivider(show: true)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.showBottomDivider(show: false)

    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.showBottomDivider(show: false)
    }
    
    private func showBottomDivider(show: Bool) {
        dividerView.isHidden = !show
    }
    
    func performDidScroll(scrollView: UIScrollView) {

    }
        
    func performContextMenuOperation(_ menuOperation: FTMediaContextMenuOperation,
                                     indexPath: IndexPath, mediaItem: FTMediaItem) {
        if menuOperation == .share {
            self.shareMedia(with: mediaItem, at : indexPath)
        } else if menuOperation == .openInNewWindow {
            FTFinderEventTracker.trackFinderEvent(with: "finder_content_item_openinnewwindow_tap")
            let page = mediaItem.page
            let index = allDocumentPages().firstIndex(where: { $0.uuid == page?.uuid })
            if let shelfItem = self.delegate?.currentShelfItemInShelfItemsViewController() {
                self.openItemInNewWindow(shelfItem, pageIndex: index)
            }
        }
    }
    
    private func shareMedia(with item: FTMediaItem, at indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        FTFinderEventTracker.trackFinderEvent(with: "finder_content_item_share_tap")
        if item.mediaType == .audio {
            self.shareAudio(with: item.annotation, at: cell)
        } else {
            self.shareImage(with: item.annotation, at: cell)
        }
    }
    
    private func shareImage(with annotation: FTAnnotation?, at cell: UICollectionViewCell?) {
        guard let imageAnnotation = annotation as? FTImageAnnotation else {
            return
        }
        if let url = imageAnnotation.imageContentFileItem()?.fileItemURL {
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = cell
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    private func shareAudio(with annotation: FTAnnotation?, at cell: UICollectionViewCell?) {
        guard let audioannotation = annotation as? FTAudioAnnotation else {
            return
        }
        let audioSession = FTAudioSessionManager.sharedSession()?.activeSession()
        if(audioannotation.recordingModel == audioSession?.audioRecording) {
            audioSession?.resetSession();
        }
        let loadingIndicatorViewController = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: NSLocalizedString("Exporting", comment: "Exporting"))
        audioannotation.prepareAnnotationForExport { progress in
            loadingIndicatorViewController.progress = CGFloat(progress)
        } onCompletion: { url , error in
            loadingIndicatorViewController.hide {
                if error == nil , let url = url {
                    let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    activityVC.popoverPresentationController?.sourceView = cell
                    self.present(activityVC, animated: true, completion: nil)
                }
            }
        }
    }
}

extension FTMediaViewController: FTMediaDelegate, FTMediaFilterViewDelegate {
    func didTapMoreOption(cell: UICollectionViewCell, item: FTMediaItem?) {
        if let annotation = item?.annotation as? FTAudioAnnotation {
            FTFinderEventTracker.trackFinderEvent(with: "finder_content_item_more_tap")
            FTAudioTrackController.showAsPopover(fromSourceView: cell, overViewController: self, with: CGSize(width: 330, height: 290),  annotations: [annotation], mode: .finder, selectedAnnotation: annotation)
        }
    }
    
    func didDismissMediaFilterView(_ type: FTMediaProtocol) {
        updateAndReloadCollectionView()
    }
}
