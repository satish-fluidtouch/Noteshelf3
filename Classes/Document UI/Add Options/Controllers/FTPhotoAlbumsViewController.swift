//
//  FTPhotoAlbumsViewController.swift
//  Noteshelf
//
//  Created by Siva on 25/04/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import Photos
import FTCommon

extension UIImagePickerController {
    override open var shouldAutorotate: Bool {
        return true
    }
    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .all
    }
}

class FTPhotoAlbumsViewController: UIViewController, FTImagePickerDelegate, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var backBtn: FTStaticTextButton!

    weak var delegate: FTPhotosViewControllerDelegate?
    var allowMultipleSelection = false
    var shouldShowCancel = false
    var canSupportDragging: Bool = false

    var albumsLists : [PHAssetCollection] = [PHAssetCollection]()
    var selectedIndexPath: IndexPath!

    //MARK:- UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        let status = PHPhotoLibrary.authorizationStatus();
        weak var weakSelf : FTPhotoAlbumsViewController? = self;
        
        if(status == PHAuthorizationStatus.notDetermined) {
            PHPhotoLibrary.requestAuthorization({ (status) in
                DispatchQueue.main.async(execute: {
                    if(status == PHAuthorizationStatus.authorized) {
                        weakSelf?.fetchAlbumList()
                        weakSelf?.tableView.reloadData();
                    }
                    else {
                        let name = applicationName() as String;
                        let title = "Go to Settings -> \(name) -> Photos and turn it on."
                        UIAlertController.showAlert(withTitle: "Photos not allowed", message: title, from: self, withCompletionHandler: {
                            self.backButtonTapped(nil)
                        });
                    }
                });
            });
            return;
        }
        else if(status == PHAuthorizationStatus.authorized) {
            self.fetchAlbumList();
        }
        else {
            let name = applicationName() as String;
            let title = "Go to Settings -> \(name) -> Photos and turn it on."
            UIAlertController.showAlert(withTitle: "Photos not allowed", message: title, from: self, withCompletionHandler: {
                self.backButtonTapped(nil)                
            });
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.shouldShowCancel {
            self.backBtn.setTitle(NSLocalizedString("Cancel", comment: "Cancel"), for: .normal)
            self.backBtn.titleLabel?.addCharacterSpacing(kernValue: -0.41)
            self.backBtn.setImage(nil, for: .normal)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        self.updateCloseButtonVisibility();
    }
    
    //MARK:- Custom
    private func fetchAlbumList() {
        
        let fetchOptions = PHFetchOptions();
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)];
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        
        let al = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype: PHAssetCollectionSubtype.any, options: nil);
        
        let smartAlbumSubTypesSupported : [PHAssetCollectionSubtype] = [
            PHAssetCollectionSubtype.smartAlbumFavorites
            ,PHAssetCollectionSubtype.smartAlbumSelfPortraits
            ,PHAssetCollectionSubtype.smartAlbumPanoramas
            ,PHAssetCollectionSubtype.smartAlbumScreenshots
            ,PHAssetCollectionSubtype.smartAlbumLivePhotos
        ];
        
        self.albumsLists = [PHAssetCollection]();
        smartAlbumSubTypesSupported.forEach { (subtype) in
            autoreleasepool {
                let smartal = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: subtype, options: nil);
                for i in 0..<smartal.count {
                    let album = smartal.object(at: i)
                    var assetCount = album.estimatedAssetCount;
                    if assetCount == NSNotFound {
                        assetCount = PHAsset.fetchAssets(in: album, options: fetchOptions).count
                    }
                    
                    if(assetCount > 0) {
                        self.albumsLists.append(album);
                    }
                }
            }
        };

        for i in 0..<al.count {
            self.albumsLists.append(al.object(at: i));
        }
    }
    
    private func updateCloseButtonVisibility() {
    }
        
    @IBAction func cameraClicked() {
        if let _ = self.delegate?.handleCameraClickInPhotosCollectionViewController {
            self.delegate?.handleCameraClickInPhotosCollectionViewController!(self);
        }
        else {
            FTImagePicker.shared.showImagePickerController(from: self)
        }
    }

    //MARK:- FTImagePickerDelegate
    func didFinishPicking(image: UIImage, picker: UIImagePickerController) {
        self.dismiss(animated: true) {
            self.delegate?.photosCollectionViewController(self, didFinishPickingPhotos: [image],isCamera: true)
        }
        print("test")
    }
    
    //MARK:- Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let photosCollectionViewController = segue.destination as? FTPhotosViewController {
            photosCollectionViewController.delegate = self.delegate
            photosCollectionViewController.canSupportDragging = self.canSupportDragging
            
            let fetchOptions = PHFetchOptions();
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)];
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
   
            let assets: PHFetchResult<AnyObject>;
            if self.selectedIndexPath.item == 0 {
                photosCollectionViewController.albumTitle = NSLocalizedString("All Photos", comment: "All Photos")
                assets = PHAsset.fetchAssets(with: fetchOptions) as! PHFetchResult<AnyObject>;
            }
            else {
//                let asset = self.albums![self.selectedIndexPath.item - 1];
                let asset = self.albumsLists[self.selectedIndexPath.item - 1];
                photosCollectionViewController.albumTitle = asset.localizedTitle
                assets = PHAsset.fetchAssets(in: asset, options: fetchOptions) as! PHFetchResult<AnyObject>;
            }
            
            photosCollectionViewController.fetchResult = assets;
        }
    }
    
    //MARK:- UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if(self.albums == nil) {
//            return 0;
//        }
//        return 1 + self.albums!.count; //AllPhotos will be available always
        return 1 + self.albumsLists.count; //AllPhotos will be available always
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellPhotoAlbum", for: indexPath) as! FTPhotoAlbumTableViewCell;

        let assets: PHFetchResult<AnyObject>;
        
        let fetchOptions = PHFetchOptions();
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)];
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        if indexPath.item == 0 {
            cell.titleLabel.styleText = NSLocalizedString("All Photos", comment: "All Photos");
            cell.titleLabel.addCharacterSpacing(kernValue: -0.32)
            assets = PHAsset.fetchAssets(with: fetchOptions) as! PHFetchResult<AnyObject>;
        }
        else {
            let album = self.albumsLists[indexPath.item - 1];

//            let album = self.albums![indexPath.item - 1];
            cell.titleLabel.styleText = album.localizedTitle;
            
            assets = PHAsset.fetchAssets(in: album, options: fetchOptions) as! PHFetchResult<AnyObject>;
        }
        cell.countLabel.styleText = "\(assets.count)";

        if let asset = assets.firstObject as? PHAsset {
            
            let options = PHImageRequestOptions();
            options.resizeMode = .exact;
            
            let scale = UIScreen.main.scale;
            let dimension = CGFloat(70);
            let size = CGSize(width: dimension * scale, height: dimension * scale);
            
            PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: PHImageContentMode.aspectFill, options: options) { (image, info) in
                runInMainThread {
                    cell.thumbnailImageView.image = image;
                };
            }
        }
        else {
            cell.thumbnailImageView.image = nil;
        }

        
        return cell;
    }
    
    //MARK:- UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true);
        
        self.selectedIndexPath = indexPath;
        self.performSegue(withIdentifier: "Segue_PhotoAlbums_to_Photos", sender: nil);
    }

}
