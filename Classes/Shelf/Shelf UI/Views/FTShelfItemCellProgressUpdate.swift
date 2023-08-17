//
//  FTShelfItemCellProgressUpdate.swift
//  Noteshelf
//
//  Created by Amar on 24/04/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

enum FTAnimType : Int
{
    case none
    case download
    case upload;
}

protocol FTShelfItemCellProgressUpdate : NSObjectProtocol {
    var pieProgressView : FTRoundProgressView? { get set}
    var statusImageView : UIImageView? { get set}
    var shelfItem: FTShelfItemProtocol? {get set}
    
    var progressObserver: NSKeyValueObservation?{get set}
    var downloadedStatusObserver: NSKeyValueObservation?{get set}
    var uploadingStatusObserver: NSKeyValueObservation?{get set}
    var downloadingStatusObserver: NSKeyValueObservation?{get set}
    var uploadedStatusObserver: NSKeyValueObservation?{get set}
    
    var animType : FTAnimType { get set}

    func updateDownloadStatusFor(item : FTShelfItemProtocol);
    func stopAnimation();
    
    var cloudImage : UIImage { get }
    var uploadingImage : UIImage { get }
    
    func startObservingProgressUpdates()
    func stopObservingProgressUpdates()
    func didFinishUpdating()
}

extension FTShelfItemCellProgressUpdate
{
    var cloudImage: UIImage {
        return UIImage(systemName: "icloud.and.arrow.down") ?? UIImage()
    }

    var uploadingImage : UIImage {
        return UIImage(named: "badgearrowup")!;
    }
    func startObservingProgressUpdates(){
        self.stopObservingProgressUpdates()
        self.progressObserver = (self.shelfItem as? FTDocumentItem)?.observe(\.downloadProgress,
                                                     options: [.new, .old]) { [weak self] (shelfItem, _) in
                                                        runInMainThread {
                                                            self?.updateDownloadStatusFor(item: shelfItem)
                                                        }
        }
        self.downloadingStatusObserver = (self.shelfItem as? FTDocumentItem)?.observe(\.isDownloading,
                                                                                      options: [.new, .old]) { [weak self] (shelfItem, _) in
                                                                                        runInMainThread {
                                                                                            self?.updateDownloadStatusFor(item: shelfItem)
                                                                                        }
        }
        self.downloadedStatusObserver = (self.shelfItem as? FTDocumentItem)?.observe(\.downloaded,
                                                                             options: [.new, .old]) { [weak self] (shelfItem, _) in
                                                                                runInMainThread {
                                                                                    if(CloudBookDownloadDebuggerLog) {
                                                                                        FTCLSLog("Book: \(shelfItem.displayTitle ?? "noName"): Downloaded")
                                                                                    }
                                                                                    self?.updateDownloadStatusFor(item: shelfItem)
                                                                                    self?.didFinishUpdating()
                                                                                }
        }
        self.uploadedStatusObserver = (self.shelfItem as? FTDocumentItem)?.observe(\.isUploaded,
                                                                             options: [.new, .old]) { [weak self] (shelfItem, _) in
                                                                                runInMainThread {
                                                                                    self?.updateDownloadStatusFor(item: shelfItem)
                                                                                }
        }
        self.uploadingStatusObserver = (self.shelfItem as? FTDocumentItem)?.observe(\.isUploading,
                                                                                   options: [.new, .old]) { [weak self] (shelfItem, _) in
                                                                                    runInMainThread {
                                                                                        self?.updateDownloadStatusFor(item: shelfItem)
                                                                                    }
        }
    }
    func stopObservingProgressUpdates(){
        self.stopAnimation()
        self.progressObserver?.invalidate()
        self.downloadedStatusObserver?.invalidate()
        self.downloadingStatusObserver?.invalidate()
        self.uploadedStatusObserver?.invalidate()
        self.uploadingStatusObserver?.invalidate()
    }
    func updateDownloadStatusFor(item : FTShelfItemProtocol)
    {
        self.pieProgressView?.isHidden = false;
        self.statusImageView?.image = nil;
        if let documentItem = item as? FTDocumentItem {
            if(documentItem.isDownloading) {
                let progress = min(CGFloat(documentItem.downloadProgress)/100,0.9);
                self.animType = .download;
                self.startDownloadAnimation();
                self.pieProgressView?.progress = progress;
            }
            else if ((documentItem.isDownloaded)) {
                self.pieProgressView?.endAnimation();
                if(self.animType != .upload){
                    self.stopAnimation(true);
                }
            }
            else if(documentItem.URL.downloadStatus() == .notDownloaded) {
                self.statusImageView?.image = self.cloudImage;
            }
            
            if documentItem.isUploading {
                self.animType = .upload;
                self.startUploadAnimation();
                self.statusImageView?.image = self.uploadingImage;
            }
            else if ((documentItem.isUploaded) && (self.animType != .download)){
                self.stopAnimation();
            }
        }
    }
    
    fileprivate func startDownloadAnimation()
    {
        if let pieProgressView = self.pieProgressView, (nil == pieProgressView.roundProgressLayer) {
            pieProgressView.startAnimation();
        }
    }
    
    fileprivate func startUploadAnimation()
    {
        let anim = self.statusImageView?.layer.animation(forKey: "alphaAnim");
        if(nil == anim) {
            let basicAnimation = CABasicAnimation.init(keyPath: "opacity");
            basicAnimation.fromValue = NSNumber.init(value: 1);
            basicAnimation.toValue = NSNumber.init(value: 0);
            basicAnimation.duration = 0.5;
            basicAnimation.autoreverses = true;
            basicAnimation.repeatCount = MAXFLOAT;
            self.statusImageView?.layer.add(basicAnimation, forKey: "alphaAnim");
        }
    }
    
    fileprivate func stopAnimation(_ progressComplete : Bool)
    {
        self.animType = .none;
        if(!progressComplete) {
            self.pieProgressView?.resetToDefaults();
        }
        self.statusImageView?.layer.removeAnimation(forKey: "alphaAnim")
    }

    func stopAnimation()
    {
        self.stopAnimation(false);
    }
}
