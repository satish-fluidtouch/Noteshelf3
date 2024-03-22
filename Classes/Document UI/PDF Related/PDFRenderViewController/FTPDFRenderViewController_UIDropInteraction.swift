//
//  FTPDFRenderViewController_UIDropInteraction.swift
//  Noteshelf
//
//  Created by Amar on 21/08/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import CoreServices
import FTCommon

private extension UIDropSession
{
    var hasImageUTITypes : Bool {
        let imageUTITypes : [String] = [UTType.image.identifier];
        return self.hasItemsConforming(toTypeIdentifiers: imageUTITypes);
    }
    
    var hasTextUTITypes : Bool {
        let textUTITypes : [String] = [UTType.text.identifier];
        return self.hasItemsConforming(toTypeIdentifiers: textUTITypes);
    }

    var hasNotebookUTITypes : Bool {
        let notebookUTITypes : [String] = [UTI_TYPE_NOTESHELF_BOOK,
                                           UTI_TYPE_NOTESHELF_NOTES];
        return self.hasItemsConforming(toTypeIdentifiers: notebookUTITypes);
    }

    var hasFileUTITypes : Bool {
        return self.hasItemsConforming(toTypeIdentifiers: supportedUTITypesForDownload());
    }
    
    var hasUrlUTITypes : Bool {
        let textUTITypes : [String] = [UTType.url.identifier];
        return self.hasItemsConforming(toTypeIdentifiers: textUTITypes);
    }


    var hasMultipleTypes : Bool {
        let supportedFileTypes = self.hasFileUTITypes;
        let supportedImageTypes = self.hasImageUTITypes;
        let supportedTextTypes = self.hasTextUTITypes;
        let noteshelfBookItems = self.hasNotebookUTITypes;
        
        let supportedArray : [Bool] = [supportedFileTypes,
                                       supportedImageTypes,
                                       supportedTextTypes,
                                       noteshelfBookItems];
        let numberOfTrue = supportedArray.filter{$0}.count

        return (numberOfTrue > 1);
    }
}

extension FTPDFRenderViewController : UIDropInteractionDelegate {
    public func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        self.normalizeAndEndEditingAnnotation(true);

        let supportedFileTypes = session.hasFileUTITypes;
        let supportedImageTypes = session.hasImageUTITypes;
        let supportedTextTypes = session.hasTextUTITypes;
        let supportedUrlTypes = session.hasUrlUTITypes;
        
        let canDrop = supportedFileTypes || supportedImageTypes || supportedTextTypes || supportedUrlTypes;
        
        let hasMultipleTypes = (session.items.count > 1) && session.hasMultipleTypes;

        let hasMultipleImages = supportedImageTypes && (session.items.count > 5);
        let hasMultipleTexts = supportedTextTypes && (session.items.count > 1);

        let canShowOverlay = (hasMultipleTypes || hasMultipleImages || hasMultipleTexts);
        if let dropController = self.dropViewController {
            dropController.view.layer.removeAllAnimations();
        }
        FTCLSLog("UI: Drop Initiated :: canDrop: \(canDrop ? "YES" : "NO")");

        if(canDrop && canShowOverlay) {
            if(nil == self.dropViewController) {
                self.addDropOverlay();
            }
            
            if let dropController = self.dropViewController {
                if(hasMultipleTypes) {
                    dropController.updateInformativeMessage(NSLocalizedString("NoMultipleTypes", comment: "Multiple file types not supported"),
                                                            andImage: "dropHereRed");
                }
                else if(hasMultipleImages) {
                    
                    dropController.updateInformativeMessage(NSLocalizedString("DropItemsCountValidationForPhotos", comment: "You can drop max five Images only"), andImage: "dropHereRed")
                } else if hasMultipleTexts {
                    dropController.updateInformativeMessage(NSLocalizedString("DropItemsCountValidationForText", comment: "You can drop only one Text"), andImage: "dropHereRed")
                }
                self.view.bringSubviewToFront(dropController.view);
                
                UIView.animate(withDuration: 0.2) {
                    dropController.view.alpha = 1.0;
                }
            }
        }
        return canDrop;
    }
    
    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal.init(operation: .copy);
    }
    
    public func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        self.dismissDropOverlay();

        let droppedPoint = session.location(in: self.mainScrollView.contentHolderView ?? self.view);
        guard let pageController = self.pageController(droppedPoint),
            let contentHolderView = pageController.contentHolderView else {
            return;
        }
        
        let hasMultipleTypes = (session.items.count > 1) && session.hasMultipleTypes;
        let supportedImageTypes = session.hasImageUTITypes;
        let supportedTextTypes = session.hasTextUTITypes;
        let supportedUrlTypes = session.hasUrlUTITypes;
        
        if hasMultipleTypes {
            return
        }
        
        if supportedTextTypes && session.items.count > 1 {
            return
        }
        if (supportedImageTypes && session.items.count > 5) {
            return
        }
        
        let dropPoint = session.location(in: contentHolderView);

        let helper = FTDropItemsHelper();
        helper.validDroppedItems(session.items) { [weak self] (droppedItems) in
            if(!droppedItems.fileItems.isEmpty) {
                var items = [FTImportItem]();
                droppedItems.fileItems.forEach { (eachItem) in
                    let item = FTImportItem(item: eachItem as AnyObject, onCompletion: nil);
                    items.append(item);
                }
                self?.beginImporting(items: items);
            }
            else if droppedItems.imageItems.count > 0 {
                self?.handleDroppedImage(droppedItems.imageItems, center: dropPoint, droppedPoint: droppedPoint)
            }
            else if let textItem = droppedItems.textItems.first {
                self?.handleDroppedText(textItem,
                                        at: dropPoint,
                                        forPageController: pageController)
            } else if let urlItem = droppedItems.urlClips.first {
                if supportedUrlTypes {
                    guard let self = self else { return }
                    FTWebClipViewController.showWebClip(overViewController: self, defaultURLString: urlItem.absoluteString,  withDelegate: self)
                }
            }
        }
    }
    
    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        self.dismissDropOverlay()
        FTCLSLog("DropSessionDidExit");
    }
    
    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
        self.dismissDropOverlay()
        FTCLSLog("DropSessionDidEnd");
    }
}

private extension FTPDFRenderViewController
{
    func addDropOverlay()
    {
        let controller = FTDroppingViewController.init(nibName: "FTDroppingViewController", bundle: nil);
        controller.view.alpha = 0.0;
        self.view.addSubview(controller.view);
        self.addChild(controller);
        
        controller.view.topAnchor.constraint(equalTo: self.view.topAnchor,
                                             constant: 0).isActive = true
        controller.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor,
                                                constant: 0).isActive = true
        controller.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor,
                                                 constant: 0).isActive = true
        controller.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor,
                                                  constant: 0).isActive = true
        
        self.dropViewController = controller;
    }
    
    func dismissDropOverlay()
    {
        if let dropViewController = self.dropViewController,
            nil != dropViewController.view.superview {
            UIView.animate(withDuration: 0.2,
                           animations: {
                            dropViewController.view.alpha = 0;
            }) { (_) in
                dropViewController.view.removeFromSuperview();
                dropViewController.removeFromParent();
            }
        }
    }
    
    func handleDroppedImage(_ droppedImage : [UIImage],center: CGPoint, droppedPoint : CGPoint)
    {
        let droppedView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 40, height: 40));
        droppedView.clipsToBounds = false;
        droppedView.image = droppedImage.first;
        droppedView.center = center;
        droppedView.contentMode = .scaleAspectFit;
        droppedView.isHidden = true;
        
        self.droppedImageView = droppedView;
        self.insert(droppedImage,
                    center:  center,
                    droppedPoint: droppedPoint,
                    //view.convert(droppedPoint, to: self.mainScrollView.contentHolderView),
            source: FTInsertImageSourceDrop);
    }
    
    private func handleDroppedText(_ droppedText : String,
                                   at droppedPoint : CGPoint,
                                   forPageController : FTPageViewController)
    {
        guard let scrollView = forPageController.scrollView else {
            return
        }

        self.switch(.deskModeText, sourceView: nil);
        
        let info = FTTextAnnotationInfo();
        info.localmetadataCache = self.pdfDocument.localMetadataCache;
        info.visibleRect = scrollView.visibleRect()
        info.scale = forPageController.pageContentScale;
        info.atPoint = droppedPoint;
        info.string = droppedText;
        forPageController.addAnnotation(info: info);
    }
}
