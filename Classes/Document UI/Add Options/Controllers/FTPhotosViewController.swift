//
//  FTPhotosViewController.swift
//  Noteshelf
//
//  Created by Siva on 25/04/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import Photos
import FTCommon
import MobileCoreServices

@objc protocol FTPhotosViewControllerDelegate : NSObjectProtocol {
    func photosCollectionViewController(_ photosCollectionViewController: UIViewController, didFinishPickingPhotos photos: [UIImage],isCamera : Bool);
    @objc optional func handleCameraClickInPhotosCollectionViewController(_ photosCollectionViewController: UIViewController);
}

class FTPhotosViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    @IBOutlet weak var doneButton: UIButton!

    @IBOutlet weak var backBtn: FTStaticTextButton!
    @IBOutlet weak var photosLabel: FTStaticTextLabel!
    @IBOutlet weak var collectionView: UICollectionView!

    weak var delegate: FTPhotosViewControllerDelegate?
    var allowMultipleSelection = false
    var canSupportDragging: Bool = false
    var albumTitle: String?
     var fetchResult: PHFetchResult<AnyObject>!;

    fileprivate let imageManager = PHCachingImageManager();
    fileprivate var thumbnailSize: CGSize!;
    fileprivate var previousPreheatRect = CGRect.zero;

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let scale = UIScreen.main.scale;
        let cellSize = (self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize;
        self.thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
        if let title = albumTitle {
            self.photosLabel.text = title
        } else {
            self.photosLabel.text = "Photos"
        }
        if self.view.frame.size.width > 400 && self.isRegularClass() {
            self.backBtn.setTitle(NSLocalizedString("Back", comment: "Back"), for: .normal)
            self.backBtn.setTitleColor(.appColor(.accent), for: .normal)
            self.backBtn.tintColor = .appColor(.accent)
            self.backBtn.setImage(UIImage(named: "nav_blueBack"), for: .normal)
            self.backBtn.titleLabel?.addCharacterSpacing(kernValue: -0.41)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCachedAssets()
    }

    override func viewDidLoad() {
        super.viewDidLoad();
        
        if canSupportDragging {
            self.allowMultipleSelection = true
            self.collectionView.dragInteractionEnabled = true
            self.collectionView.dragDelegate = self
            self.collectionView.dropDelegate = self
        }
        self.doneButton.isHidden = !self.allowMultipleSelection;
        self.collectionView.allowsMultipleSelection = self.allowMultipleSelection;
        self.resetCachedAssets();
        updateDoneButtonMode()
        self.collectionView.contentInset = UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
    }
    
    //MARK:- Custom
    
    @IBAction func doneClicked() {
        self.doneButton.isEnabled = false
        var arrayImages = [UIImage]();
        let totalSelectedItems = self.collectionView.indexPathsForSelectedItems?.count;
        var shouldProcessNext = true;
        self.collectionView.indexPathsForSelectedItems?.forEach({ (indexPath) in
            if shouldProcessNext {
                let asset = self.fetchResult[indexPath.item] as! PHAsset;
                
                self.image(forAsset: asset, withCompletionHandler: { (image, error) in
                    if let image = image {
                        arrayImages.append(image);
                        if arrayImages.count == totalSelectedItems {
                            self.delegate?.photosCollectionViewController(self, didFinishPickingPhotos: arrayImages,isCamera: false);
                            self.doneButton.isEnabled = true
                        }
                    }
                    else {
                        shouldProcessNext = false;
                        runInMainThread { [weak self] in
                            if let weakSelf = self, let error = error {
                                UIAlertController.showAlert(withTitle: "", message: error.localizedDescription, from: weakSelf, withCompletionHandler: nil);
                                self?.doneButton.isEnabled = true
                            }
                        }
                    }
                });
            }
        });
    }
      
    fileprivate func image(forAsset asset: PHAsset, isSynchronous: Bool = false, withCompletionHandler completionHandler: @escaping ((UIImage?, NSError?) -> Void)) {
        let imageRequestOptions = PHImageRequestOptions();
        imageRequestOptions.version = .current;
        imageRequestOptions.isSynchronous = isSynchronous;
        imageRequestOptions.isNetworkAccessAllowed = true;
        imageRequestOptions.deliveryMode = .highQualityFormat;

        let defaultPHImageManager = PHImageManager();
        defaultPHImageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.default, options: imageRequestOptions) { (image, info) in
            let imageToreturn = image;
            if(nil == imageToreturn) {
                FTLogError("Photo selection failed at stage1");
                defaultPHImageManager.requestImageData(for: asset, options: imageRequestOptions, resultHandler: { (data, _, imageOrientation, info) in
                    if(nil == data) {
                        let error: NSError!;
                        if let userInfo = info, let phError = userInfo["PHImageErrorKey"] as? NSError {
                            if let ckError = phError.userInfo["NSUnderlyingError"] as? NSError {
                                error = ckError;
                            }
                            else {
                                error = phError;
                            }
                        }
                        else {
                            error = NSError(domain: "com.fluidtouch.noteshelf", code: 404, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("PhotoNotAvailableToUse", comment: "Selected photo is not available to use")]);
                        }
                        FTLogError("Photo selection failed at stage2", attributes: error.userInfo);
                        completionHandler(nil, error);
                    }
                    else {
                        if let imgToReturn = UIImage.init(data: data!) {
                            completionHandler(imgToReturn, nil);
                        }
                        else {
                            let error = NSError(domain: "com.fluidtouch.noteshelf", code: 404, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("PhotoNotAvailableToUse", comment: "Selected photo is not available to use")])
                            FTLogError("Photo selection failed at stage2", attributes: error.userInfo);
                            completionHandler(nil, error);
                        }
                    }
                });
            }
            else {
                completionHandler(imageToreturn, nil);
            }
        }
    }
    
    private func showAlert() {
        let message = "DragItemsCountValidation".localized
         UIAlertController.showAlert(withTitle: message, message: "", from: self, withCompletionHandler: nil)
    }
    
    //MARK:- Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let photosCollectionViewController = segue.destination as? FTPhotosViewController {
            photosCollectionViewController.delegate = self.delegate;
        }
    }
    
    //MARK:- UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.updateCachedAssets()
    }

    //MARK:- UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fetchResult.count;
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CellPhoto", for: indexPath) as! FTPhotoCollectionViewCell;
        cell.selectionImageView.isHidden = !cell.isSelected;
        
        let asset = self.fetchResult[indexPath.item] as! PHAsset;
        
        cell.representedAssetIdentifier = asset.localIdentifier;
        self.imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil) { (image, _) in
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.thumbnailImageView.image = image
            }
        };

        cell.thumbnailImageView.isAccessibilityElement = true;
        if(cell.isSelected) {
            cell.thumbnailImageView.accessibilityTraits = [.image,.selected];
        }
        else {
            cell.thumbnailImageView.accessibilityTraits = .image
        }
        return cell
    }
    
    //MARK:- UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView.hasActiveDrag {
            self.collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        
        updateDoneButtonMode()
        
        if let totalSelectedItems = self.collectionView.indexPathsForSelectedItems {
            if totalSelectedItems.count > 5 {
                self.collectionView.deselectItem(at: indexPath, animated: true)
                UIAlertController.showAlert(withTitle: "DragItemsCountValidation".localized, message: "", from: self, withCompletionHandler: nil)
            }
        }
     
        if !canSupportDragging {
            let loadingIndicatorViewController = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: "");
            let asset = self.fetchResult[indexPath.item] as! PHAsset;
            self.image(forAsset: asset) { (image, error) in
                loadingIndicatorViewController.hide { [weak self] in
                    if let weakSelf = self, let image = image {
                        weakSelf.delegate?.photosCollectionViewController(weakSelf, didFinishPickingPhotos: [image],isCamera: false);
                    }
                    else {
                        runInMainThread { [weak self] in
                            if let weakSelf = self, let error = error {
                                UIAlertController.showAlert(withTitle: "", message: error.localizedDescription, from: weakSelf, withCompletionHandler: nil);
                            }
                        }
                    }
                }
            };
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
       updateDoneButtonMode()
    }
    
    private func updateDoneButtonMode() {
        if let totalSelectedItems = self.collectionView.indexPathsForSelectedItems {
            if !totalSelectedItems.isEmpty {
                self.doneButton.isEnabled = true
                self.doneButton.setTitleColor(UIColor.appColor(.accent).withAlphaComponent(1.0), for: .normal)
            } else {
                self.doneButton.setTitleColor(UIColor.appColor(.accent).withAlphaComponent(0.5), for: .normal)
                self.doneButton.isEnabled = false
            }
        }
    }
    
    //MARK:- Asset Caching
    fileprivate func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    
    fileprivate func updateCachedAssets() {
        // Update only if the view is visible.
        guard (self.isViewLoaded && self.view.window != nil) else {
            return;
        }
        
        // The preheat window is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        
        // Update the assets the PHCachingImageManager is caching.
        if let addedAssets = addedAssets as? [PHAsset] {
            imageManager.startCachingImages(for: addedAssets, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil);
        }
        if let removedAssets = removedAssets as? [PHAsset] {
            imageManager.stopCachingImages(for: removedAssets, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil);
        }
        
        // Store the preheat rect to compare against in the future.
        previousPreheatRect = preheatRect
    }
    
    fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                    width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                    width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                    width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                    width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
}

extension FTPhotosViewController:  UICollectionViewDragDelegate {
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        return self.selectedItems(indexPath, for: session)
    }
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        
        if collectionView != self.collectionView {
            return []
        }
        let photoItem  = self.fetchResult[indexPath.item] as! PHAsset
        
        var canAddToDragSession:Bool = true
        
        session.items.forEach { dragItem in
            if let item = dragItem.localObject as? PHAsset {
                if item.localIdentifier == photoItem.localIdentifier {
                    canAddToDragSession = false
                }
            }
        }
        
        if session.items.count >= 5 {
            canAddToDragSession = false
            UIAlertController.showAlert(withTitle: "DragItemsCountValidation".localized, message: "", from: self, withCompletionHandler: nil)
        }
        
        if canAddToDragSession {
            return self.selectedItems(indexPath, for: session)
        }
        return []
    }
    
    func getUIImage(asset: PHAsset) -> UIImage? {
        var img: UIImage?
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.version = .original
        options.isSynchronous = true
        manager.requestImageData(for: asset, options: options) { [weak self] data, _, _, _  in
            if let data = data {
                img = UIImage(data: data)
            } else {
                self?.image(forAsset: asset, isSynchronous: true) { (image, error) in
                    if error == nil {
                        img = image
                    }
                }
            }
        }
        return img
    }
    
    private func selectedItems(_ indexPath: IndexPath, for session: UIDragSession) -> [UIDragItem] {
        //Get Photo asset
        let photoItem  = self.fetchResult[indexPath.item] as! PHAsset
        
        //get Image from phasset
        if let image = getUIImage(asset: photoItem) {
            let itemProvider = NSItemProvider(object: image)
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = photoItem
            dragItem.previewProvider = { () -> UIDragPreview? in
                if let cell = self.collectionView.cellForItem(at: indexPath) as? FTPhotoCollectionViewCell {
                    let imageView = UIImageView(frame: NSItemProvider.providerPreviewRect)
                    imageView.image = cell.thumbnailImageView.image
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

extension FTPhotosViewController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        var canHandle: Bool = false
        if collectionView.hasActiveDrag && session.localDragSession != nil {
            for item in session.items {
                if let assetItem = item.localObject as? PHAsset {
                    canHandle = true
                }
            }
        }
        return canHandle
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidExit session: UIDropSession) {
        if (self.navigationController?.view != nil) {
        let point = session.location(in: self.navigationController!.view)
        if collectionView.frame.contains(point) {
        } else {
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
       
        if session.localDragSession != nil {
             return UICollectionViewDropProposal(operation: .cancel, intent: .insertAtDestinationIndexPath)
        }
        return UICollectionViewDropProposal(operation: .cancel, intent: .unspecified)
    }
}

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}

extension NSItemProvider {
    static let providerPreviewRect = CGRect(x: 0, y: 0, width: 180, height: 180)
}


