//
//  FTWritingViewController_Lasso.swift
//  Noteshelf
//
//  Created by Amar on 08/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension FTWritingViewController : FTLassoProtocol {
    //Lasso
    func lassoDidMoved(byOffset offset: CGPoint) {
        if let lassoImgView = self.lassoImageView {
            var frameRect = lassoImgView.frame;
            frameRect.origin = CGPointTranslate(frameRect.origin, offset.x, offset.y);
            lassoImgView.frame = frameRect;
        }
    }
    
    func moveSelectedAnnotations(_ annotations: [Any]!, offset: CGPoint, refreshForcibly forcibly: Bool) {
        if(!self.lassoViewPreparationIsInProgress || forcibly) {
            guard let annotationsToRender = annotations as? [FTAnnotationProtocol] else {
                return;
            }
            
            self.lassoViewPreparationIsInProgress = true;
            var annotationsMaxRect = CGRect.null;
            annotationsToRender.forEach { (annotation) in
                annotationsMaxRect = annotationsMaxRect.union(annotation.renderingRect);
            }
            annotationsMaxRect = CGRectScale(annotationsMaxRect, self.scale).integral;
            
            if(nil == self.lassoImageView) {
                self.lassoImageView = UIImageView.init(frame: annotationsMaxRect);
                self.view.addSubview(self.lassoImageView!);
                self.lassoImageView?.frame = annotationsMaxRect;
            }
            
            self.lassoImageView?.isHidden = true;
            if annotationsToRender.isEmpty == false {
                UIGraphicsBeginImageContextWithOptions(annotationsMaxRect.size, false, 0);
                let currentContext = UIGraphicsGetCurrentContext();
                currentContext?.translateBy(x: 0, y: annotationsMaxRect.height);
                currentContext?.scaleBy(x: 1, y: -1);
                
                let windowHash = self.view.window?.hash;
                self.lassoQueue.async {
                    let imageGen = FTRendererProvider.shared.dequeOffscreenRenderer();
                    
                    let tileSize = FTRenderConstants.TILE_SIZE;
                    let firstVisibleRow = Int(annotationsMaxRect.minY/CGFloat(tileSize));
                    var lastVisibleRow = Int(annotationsMaxRect.maxY/CGFloat(tileSize));
                    if(Int(annotationsMaxRect.maxY)%Int(tileSize) > 0) {
                        lastVisibleRow += 1;
                    }
                    
                    let firstVisibleColumn = Int(annotationsMaxRect.minX/CGFloat(tileSize));
                    
                    var lastVisibleColumn = Int(annotationsMaxRect.maxX/CGFloat(tileSize));
                    if(Int(annotationsMaxRect.maxX) % Int(tileSize) > 0) {
                        lastVisibleColumn += 1;
                    }
                    
                    let dispatchGroup = DispatchGroup.init();
                    let bgColor = (self.pageToDisplay as? FTPageBackgroundColorProtocol)?.pageBackgroundColor ?? .white

                    let offset = annotationsMaxRect.origin;
                    for eachRow in firstVisibleRow..<lastVisibleRow {
                        for eachCol in firstVisibleColumn..<lastVisibleColumn {
                            dispatchGroup.enter();
                            var tileRect = CGRect.zero;
                            tileRect.size = CGSize(width: FTRenderConstants.TILE_SIZE, height: FTRenderConstants.TILE_SIZE);
                            tileRect.origin.x = CGFloat(eachCol)*tileRect.width;
                            tileRect.origin.y = CGFloat(eachRow)*tileRect.height;
                            let request = FTOffScreenTileImageRequest(with: windowHash);
                            request.label = "LASSO_TILE_MOVE"
                            request.backgroundColor = bgColor
                            request.areaToRefresh = tileRect;
                            request.annotations = annotationsToRender;
                            request.contentSize = self.contentSize;
                            request.scale = self.scale;
                            request.completionBlock = { [weak self] (image) in
                                self?.lassoQueue.async {
                                    var imagerenderArea = tileRect;
                                    imagerenderArea.origin.x -= offset.x;
                                    imagerenderArea.origin.y -= offset.y;
                                    
                                    imagerenderArea.origin.y = (annotationsMaxRect.height-imagerenderArea.origin.y-imagerenderArea.size.height);
                                    
                                    if let cgimage = image?.cgImage {
                                        currentContext?.draw(cgimage, in: imagerenderArea);
                                    }
                                    dispatchGroup.leave();
                                }
                            };
                            imageGen.imageFor(request: request);
                        }
                    }
                    
                    dispatchGroup.notify(queue: self.lassoQueue, execute: {
                        DispatchQueue.main.async { [weak self] in
                            let newImage = UIGraphicsGetImageFromCurrentImageContext();
                            UIGraphicsEndImageContext();
                            FTRendererProvider.shared.enqueOffscreenRenderer(imageGen)
                            let properties = FTRenderingProperties();
                            properties.renderImmediately = true;
                            properties.pageID = self?.pageToDisplay?.uuid;
                            self?.reloadTiles(forIntents: [.offScreen,.onScreen],
                                                        rect: annotationsMaxRect,
                                                        properties: properties);
                            self?.lassoImageView?.image = newImage;
                            self?.lassoImageView?.isHidden = false;
                            if let lassoview = self?.lassoImageView {
                                self?.view.bringSubviewToFront(lassoview)
                            }
                        }
                    });
                }
            }
        }
        if let lassoImgView = self.lassoImageView {
            var frameRect = lassoImgView.frame;
            frameRect.origin.x += offset.x;
            frameRect.origin.y += offset.y;
            lassoImgView.frame = frameRect;
        }
    }
    
    func finalizeSelection(byAddingAnnotations annotations: [Any]?)
    {
        self.lassoViewPreparationIsInProgress = false;
        self.lassoImageView?.isHidden = true;
        self.lassoImageView?.removeFromSuperview();
        self.lassoImageView = nil;
        if let annotationToAdd = annotations as? [FTAnnotation] {
            self.addAnnotations(annotationToAdd,
                                refreshView: true);
        }
        else {
            if let scrollView = self.scrollView {
                let properties = FTRenderingProperties();
                properties.renderImmediately = true;
                properties.synchronously = true;
                properties.pageID = self.pageToDisplay?.uuid;
                self.reloadTiles(forIntents: [.offScreen,.onScreen],
                                 rect: scrollView.visibleRect(),
                                 properties: properties);
            }
        }
    }
    
    internal func stopLassoOperationAndNotifiy(_ completionBlock : @escaping (Bool,String) -> ())
    {
        self.lassoQueue.async {
            completionBlock(true,"lasso");
        }
    }
}
