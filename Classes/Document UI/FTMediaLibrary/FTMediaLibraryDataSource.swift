//
//  FTMediaLibraryDataSource.swift
//  FTAddOperations
//
//  Created by Siva Kumar Reddy on 05/07/20.
//  Copyright © 2020 Siva. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage
import MobileCoreServices
import FTNewNotebook

protocol FTMediaLibraryDataSourceDelegate: AnyObject {
    func fetchMediaForPage(forPage: Int)
    func didSelectMediaImage( _ clipartImage: UIImage)
    func dropSessionDidExit(dropSession session: UIDropSession)
    func showAlert(title: String, message: String)
}

class FTMediaLibraryDataSource: NSObject {
    weak var delegate: FTMediaLibraryDataSourceDelegate?
    lazy var layout = FTCollectionViewWaterfallLayout()

    var collectionView: UICollectionView!
    var minimumColumnSpacing : CGFloat = 12.0
    var minimumInterItemSpacing : CGFloat = 12.0
    var localProvider = FTLocalMediaLibraryProvider()
    private var itemProvider : NSItemProvider?
    private var loadingView: FTLoadingReusableView?
    private var page: Int = 1
    var isLoading = false
    var cellType: MediaCellTypes = .empty
    weak var viewController: UIViewController!
    private let manager = FTMediaLibraryManager()

    var mediaLibraryArray: [FTMediaLibraryModel] = []  {
        didSet {
            refreshUI()
        }
    }
    required convenience init(with collectionView: UICollectionView?, viewController: UIViewController?) {
        self.init()
        self.collectionView = collectionView
        self.viewController = viewController
        //Register Loading Reuseable View
        let loadingReusableNib = UINib(nibName: "FTLoadingReusableView", bundle: nil)
        self.collectionView.register(loadingReusableNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "loadingresuableviewid")

        /// Configure No Recents ReusableView
        let noRecentNib = UINib(nibName: "FTNoRecentsReusableView", bundle: nil)
        self.collectionView.register(noRecentNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "noRecents")

        /// Configure No Internet ReusableView
        let noInternetViewNib = UINib(nibName: "FTNoInternetReusableView", bundle: nil)
        self.collectionView.register(noInternetViewNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "noInternet")

        
        // Configure Empty Cell
        self.collectionView.register(FTEmptyCollectionViewCell.self, forCellWithReuseIdentifier: "emptyCell")

        layout.minimumColumnSpacing = minimumColumnSpacing
        layout.minimumInteritemSpacing = minimumInterItemSpacing

        self.collectionView.collectionViewLayout  = layout
        self.collectionView.dragInteractionEnabled = true
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.dragDelegate = self
        self.collectionView.dropDelegate = self
        refreshUI()
    }
    deinit {
#if DEBUG
        debugPrint("deinit :\(self)");
#endif
    }
    
    func refreshUI(){
        DispatchQueue.main.async {
            self.layout.invalidateLayout()
            if self.cellType == .norecent || self.cellType == .noInternet || self.cellType == .noRecords {
                self.layout.isErrorScreen = true
            }
            else {
                self.layout.isErrorScreen = false
            }
            self.setLineAndInterItemSpacing()
            self.collectionView?.reloadData()
        }
    }

    func loadMoreData() {
        if !self.isLoading {
            self.isLoading = true
            page += 1
            self.delegate?.fetchMediaForPage(forPage: page)
        }
    }
    func setLineAndInterItemSpacing(){
        layout.minimumColumnSpacing = self.minimumColumnSpacing
        layout.minimumInteritemSpacing = self.minimumInterItemSpacing
        self.collectionView.collectionViewLayout  = layout
    }
    @objc func longPressed(sender: UILongPressGestureRecognizer) {
        if sender.state == .began && cellType == .recent {
            cellType = .editing
            for cell in collectionView!.visibleCells as! [FTMediaLibraryCell] {
                cell.startWiggle()
                cell.deleteButton?.isHidden = false
            }
        }
        else if sender.state == .ended ||  sender.state == .changed {
            let seconds = 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                // Put your code which should be executed with a delay here
                self.layout.invalidateLayout()
                self.collectionView.reloadData()
            }
        }
    }
}

// MARK: - CollectionView Data Source & Delegates
extension FTMediaLibraryDataSource: UICollectionViewDataSource, UICollectionViewDelegate, FTCollectionViewDelegateWaterfallLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if cellType != .normal {
            return mediaLibraryArray.count > 0 ? mediaLibraryArray.count : 1
        }
        else {
            return mediaLibraryArray.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = UICollectionViewCell()
        switch cellType {
        case .empty:
            return  self.collectionView(collectionView, emptyCellForItemAt: indexPath)
        case .normal:
            return  self.collectionView(collectionView, normalCellForItemAt: indexPath)
        case .recent:
            return  self.collectionView(collectionView, recentCellForItemAt: indexPath)
        case .norecent:
            return  self.collectionView(collectionView, emptyCellForItemAt: indexPath)
        case .editing:
            return  self.collectionView(collectionView, editCellForItemAt: indexPath)
        case .noInternet:
            return  self.collectionView(collectionView, emptyCellForItemAt: indexPath)
        case .noRecords:
            return  self.collectionView(collectionView, emptyCellForItemAt: indexPath)
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, emptyCellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "emptyCell", for: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, normalCellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTClipartCell", for: indexPath)
        if let clipartCell = cell as? FTMediaLibraryCell, !mediaLibraryArray.isEmpty  {
            let clipart = mediaLibraryArray[indexPath.item]
            clipartCell.configure(with: clipart, isEditing: false)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, recentCellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTClipartCell", for: indexPath)
        if let cell = cell as? FTMediaLibraryCell, !mediaLibraryArray.isEmpty {
            let clipart = mediaLibraryArray[indexPath.item]
            cell.configure(with: clipart, isEditing: false)
            let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
            cell.addGestureRecognizer(longPressRecognizer)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, editCellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTClipartCell", for: indexPath)
        if let cell = cell as? FTMediaLibraryCell, !mediaLibraryArray.isEmpty {
            let clipart = mediaLibraryArray[indexPath.item]
            cell.configure(with: clipart, isEditing: true)
            cell.deleteLocalClipart = { [weak self] recentClipart in
                self?.deleteRecentClipart(clipart: recentClipart)
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.hasActiveDrag {
            self.collectionView.deselectItem(at: indexPath, animated: true)
            return
        }

        if cellType == .editing {
            cellType = .recent
            self.collectionView.reloadData()
            return
        }
        if !mediaLibraryArray.isEmpty {
            let clipart = mediaLibraryArray[indexPath.item]
            didSelectClipart(clipart)
        }
        if cellType == .recent {
            let clipart = mediaLibraryArray[indexPath.item]
            self.reOrderRecentClipart(clipart: clipart)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row == mediaLibraryArray.count - 10 && !self.isLoading {
            loadMoreData()
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            let aFooterView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "loadingresuableviewid", for: indexPath)
            if let aFooterView = aFooterView as? FTLoadingReusableView  {
                loadingView = aFooterView
                loadingView?.backgroundColor = UIColor.clear
                return aFooterView
            }
        }
        else if kind == UICollectionView.elementKindSectionHeader {
            if cellType == .norecent || cellType == .noRecords {
                let noRecentsView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "noRecents", for: indexPath)
                if let noRecentsView = noRecentsView as? FTNoRecentsReusableView  {
                    if cellType == .norecent {
                        noRecentsView.titleLbl?.text = "NoRecents".localized
                    }
                    else  if cellType == .noRecords {
                        noRecentsView.titleLbl?.text = "NoResults".localized
                    }
                    return noRecentsView
                }
            }
            else if cellType == .noInternet {
                let noRecentsView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "noInternet", for: indexPath)
                if let noRecentsView = noRecentsView as? FTNoInternetReusableView  {
                    return noRecentsView
                }
            }

        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        if elementKind == UICollectionView.elementKindSectionFooter  {
            self.loadingView?.activityIndicator.startAnimating()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        if elementKind == UICollectionView.elementKindSectionFooter {
            self.loadingView?.activityIndicator.stopAnimating()
        }
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, heightForFooterIn section: Int) -> CGFloat {
        if !self.isLoading {
            return 50
        }
        return 0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, heightForHeaderIn section: Int) -> CGFloat {
        if cellType == .norecent || cellType == .noRecords || cellType == .noInternet {
            return self.collectionView.frame.size.height
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if !mediaLibraryArray.isEmpty {
            let item = mediaLibraryArray[indexPath.item] as FTMediaLibraryModel
            if let h = item.height, let w = item.width {
                if item.clipartDescription == "UnSplash" {
                    return CGSize(width: w, height: h + 25)
                }
                return CGSize(width: w, height: h)
            }
        }
        return CGSize(width: 0, height: 0)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetsFor section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
}

//MARK:- UICollectionViewDragDelegate
extension FTMediaLibraryDataSource: UICollectionViewDragDelegate {
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
#if targetEnvironment(macCatalyst)
        return []
#else
        return self.selectedItem(at: indexPath, for: session)
#endif
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        
        let clipItem: FTMediaLibraryModel
        clipItem =  mediaLibraryArray[indexPath.item]
        var canAddToDragSession:Bool = true
        
        session.items.forEach { dragItem in
            if let item = dragItem.localObject as? FTMediaLibraryModel {
                if item.id == clipItem.id {
                    canAddToDragSession = false
                }
            }
        }
        
        if session.items.count >= 5 {
            canAddToDragSession = false
            let message = NSLocalizedString("DragItemsCountValidation", comment: "Can't add more than 5 photos at a time")
            self.delegate?.showAlert(title: message, message: "")
        }
        
        if canAddToDragSession {
            return self.selectedItem(at: indexPath, for: session)
        }
        
        return []
    }
    
    private func selectedItem(at indexPath: IndexPath, for session:UIDragSession) -> [UIDragItem] {
        
#if targetEnvironment(macCatalyst)
        return []
#endif
        
        let mediaModel: FTMediaLibraryModel

        mediaModel =  mediaLibraryArray[indexPath.item]

        if let mediaImage = SDImageCache.shared.imageFromDiskCache(forKey: "\(mediaModel.id)") {
            itemProvider = NSItemProvider(object: mediaImage)
        } else {
            itemProvider = NSItemProvider()
            itemProvider?.suggestedName = mediaModel.title
            itemProvider?.registerFileRepresentation(forTypeIdentifier: kUTTypePNG as String, fileOptions: NSItemProviderFileOptions.openInPlace, visibility: .all) { completionHandler in
                ///DownloadUnsplashImage
                self.downloadUnSplashImage(mediaModel)
                
                let dataProgress:Progress = Progress()
                if let urlString = mediaModel.urls?.png_full_lossy,let mediaUrl = URL(string: urlString) {
                    SDWebImageManager.shared.loadImage(with: mediaUrl,
                                                       options: .refreshCached,
                                                       progress: { (receivedSize, expectedSize, _) in
                        dataProgress.totalUnitCount = Int64(expectedSize)
                        dataProgress.completedUnitCount = Int64(receivedSize)
                    }) { (image, _, error, _, _, _) in
                        runInMainThread {
                            if error == nil && image != nil{
                                SDImageCache.shared.store(image, forKey: "\(mediaModel.id)", toDisk: true) {
                                    if let mediaFilePath = SDImageCache.shared.cachePath(forKey: "\(mediaModel.id)") {
                                        completionHandler(URL(fileURLWithPath: mediaFilePath),true,nil)
                                    }
                                }
                            } else {
                                completionHandler(nil,false,error)
                            }
                        }
                    }
                }
                return dataProgress
            }
        }
        if let provider = itemProvider {
            let dragItem = UIDragItem(itemProvider: provider)
            dragItem.localObject = mediaModel
            dragItem.previewProvider = { () -> UIDragPreview? in
                if let cell = self.collectionView.cellForItem(at: indexPath) as? FTMediaLibraryCell {
                    let imageView = UIImageView(frame: NSItemProvider.providerPreviewRect)
                    imageView.backgroundColor = UIColor.white
                    imageView.image = cell.thumbnail.image
                    imageView.contentMode = .scaleAspectFit
                    return UIDragPreview(view: imageView)
                }
                return nil
            }
            return [dragItem]
        }
        return []
    }
}

//MARK:- UICollectionViewDropDelegate
extension FTMediaLibraryDataSource: UICollectionViewDropDelegate {
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        var canHandle: Bool = false
        if collectionView.hasActiveDrag && session.localDragSession != nil {
            for item in session.items {
                if let assetItem = item.localObject as? FTMediaLibraryModel {
                    canHandle = true
                }
            }
        }
        return canHandle
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }
        if cellType == .recent || cellType == .editing {
            if coordinator.session.localDragSession != nil {
                collectionView.performBatchUpdates({
                    for pageItem in coordinator.items {
                        if let localObject = pageItem.dragItem.localObject as AnyObject as? FTMediaLibraryModel {
                            if let sourceIndexPath = pageItem.sourceIndexPath {
                                if localObject.isLocal {
                                    mediaLibraryArray.remove(at: sourceIndexPath.item)
                                    collectionView.deleteItems(at: [sourceIndexPath])
                                }
                            }
                            if localObject.isLocal {
                                mediaLibraryArray.insert(localObject, at: destinationIndexPath.item)
                                coordinator.drop(pageItem.dragItem, toItemAt: destinationIndexPath)
                                collectionView.insertItems(at: [destinationIndexPath])
                                self.localProvider.reorderMediaInLocal(with: self.mediaLibraryArray)
                            }
                        }

                    }
                }, completion: nil)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidExit session: UIDropSession) {
        self.delegate?.dropSessionDidExit(dropSession: session)
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        
        if session.localDragSession != nil {
            if cellType == .recent  || cellType == .editing{
                return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            }
            return UICollectionViewDropProposal(operation: .cancel, intent: .insertAtDestinationIndexPath)
        }
        return UICollectionViewDropProposal(operation: .cancel, intent: .unspecified)
    }
}

// MARK: - Private
fileprivate extension FTMediaLibraryDataSource {
    
    func didSelectClipart(_ clipart: FTMediaLibraryModel) {
        track("clipart_insert", params: ["source": clipart.isLocal ? "Local" : "Remote"])
        guard let urlString = clipart.urls?.png_full_lossy, let clipartURL = URL(string: urlString) else { return }
        if let clipartImage = SDImageCache.shared.imageFromCache(forKey: "\(clipart.id)"){
            if !clipart.isLocal {
                self.localProvider.addMediaLibraryModelToLocal(mediaLibraryModel: clipart)
            }
            self.delegate?.didSelectMediaImage(clipartImage)
        }
        else {
            let loadingIndicatorViewController = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self.viewController, withText: NSLocalizedString("Downloading", comment: "Downloading..."));
            ///DownloadUnsplashImage
            downloadUnSplashImage(clipart)
            
            let dataProgress:Progress = Progress()
            SDWebImageManager.shared.loadImage(with: clipartURL,
                                               options: .refreshCached,
                                               progress: { (receivedSize, expectedSize, _) in
                dataProgress.totalUnitCount = Int64(expectedSize)
                dataProgress.completedUnitCount = Int64(receivedSize)
            }) { [weak self] (image, _, error, _, _, _) in
                guard let self = self else { return }
                runInMainThread {
                    if error == nil {
                        if let clipArtImage = image {
                            self.localProvider.addMediaLibraryModelToLocal(mediaLibraryModel: clipart)
                            SDImageCache.shared.store(image, forKey: "\(clipart.id)", toDisk: true) {
                                self.delegate?.didSelectMediaImage(clipArtImage)
                                loadingIndicatorViewController.hide(nil)
                            }
                        }
                    } else {
                        loadingIndicatorViewController.hide()
                    }
                }
            }
        }
    }
    
    func downloadUnSplashImage(_ clipart: FTMediaLibraryModel)  {
        guard let urlString = clipart.links?.download_location else { return }
        DispatchQueue.global(qos: .background).async {
            self.manager.searchUnSplash(type: UnSplashDownloadModel.self, service: FTUnsplashPostService.downloadImage(downloadUrl: urlString)) { response in
                switch response {
                case let .successWith(posts):
                    print(posts)
                case let .failureWith(error):
                    print(error)
                }
            }
        }
    }
    
    func deleteRecentClipart(clipart: FTMediaLibraryModel) {
        localProvider.removeMediaLibraryModelFromLocal(localMediaLibraryModel: clipart)
        collectionView.performBatchUpdates({ [weak self] in
            if let index = self?.mediaLibraryArray.lastIndex(where: { $0.id == clipart.id }) {
                self?.mediaLibraryArray.remove(at: index)
                if self?.mediaLibraryArray.count == 0 {
                    self?.cellType = .norecent
                }
                self?.collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
            }
        })
    }
    func reOrderRecentClipart(clipart: FTMediaLibraryModel) {
        if let index = self.mediaLibraryArray.lastIndex(where: { $0.id == clipart.id }) {
            self.mediaLibraryArray.remove(at: index)
            self.mediaLibraryArray.insert(clipart, at: 0)
            localProvider.reorderMediaInLocal(with: self.mediaLibraryArray)
        }
    }
}

class FTEmptyCollectionViewCell: UICollectionViewCell {
    
}
