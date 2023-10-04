//
//  FTPDFRenderViewController+Refresh.swift
//  Noteshelf
//
//  Created by Siva on 27/03/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import PhotosUI
import FTCommon

@objcMembers class FTScrollViewPageOffset: NSObject {
    var pageNo: Int = 0;
    var offset: CGPoint = CGPoint.zero;
}

extension FTPDFRenderViewController {
    @objc func addObserverForPageLayoutChange()
    {
        NotificationCenter.default.addObserver(forName: .pageLayoutDidChange,
                                               object: nil,
                                               queue: nil)
        { [weak self] (_) in
            guard let strongSelf = self else {
                return;
            }
            strongSelf.updatePageLayout();
        }
    }
    
    @objc func updatePageLayout() {
        guard let docScrollView = self.mainScrollView else {
            fatalError("scrollview should be of type: FTDocumentScrollView");
        }
        
        let layout: FTPageLayout = UserDefaults.standard.pageLayoutType;
        let shouldMaintainPageOnLayout = (nil != self.pageLayoutHelper);

        let curPageIndex: Int = self.currentlyVisiblePage()?.pageIndex() ?? 0;
        let prevLayoutType = self.pageLayoutHelper?.layoutType ?? FTPageLayout.horizontal;
        
        self.pageLayoutHelper = FTLayouterFactory.layouter(type: layout, scrollView: docScrollView);
        self.pageLayoutHelper.delegate = self;
        self.pageLayoutHelper.document = self.pdfDocument;
        self.addRefresh(layout: layout, scrollView: docScrollView);
        docScrollView.setPageLayoutType(layout);
        
        if(shouldMaintainPageOnLayout) {
            self.maintainCurrentPageOnLayoutChange(curPageIndex,
                                                   previousLayoutType: prevLayoutType);
        }
    }
    
    @objc func updateContentOffsetPercentage() {
        guard let curPage = self.currentlyVisiblePage() else {
            return;
        }
        contentOffsetPercentage = FTScrollViewPageOffset();
        let pageIndex = curPage.pageIndex();
        contentOffsetPercentage.pageNo = pageIndex;
        let viewFrame = self.pageLayoutHelper.frame(for: pageIndex);
        
        var contentOffset = self.mainScrollView.contentOffset;
        contentOffset.x -= viewFrame.minX;
        contentOffset.y -= viewFrame.minY;
        contentOffset.x /= viewFrame.width;
        contentOffset.y /= viewFrame.height;
        contentOffsetPercentage.offset = contentOffset;
    }
    
    @objc func mappedContentOffset() -> CGPoint {
        let offset = self.contentOffsetPercentage ?? FTScrollViewPageOffset();
        
        let viewFrame = self.pageLayoutHelper.frame(for: offset.pageNo);
        var newOffset = offset.offset;
        newOffset.x *= viewFrame.width;
        newOffset.y *= viewFrame.height;

        newOffset.x += viewFrame.minX;
        newOffset.y += viewFrame.minY;
        
        let contentSizeWidth = self.mainScrollView.contentSize.width;
        let contentSizeHeight = self.mainScrollView.contentSize.height;
        
        let scrollViewWidth = self.mainScrollView.frame.size.width;
        let scrollViewHeight = self.mainScrollView.frame.size.height;
        
        var maxX = contentSizeWidth - scrollViewWidth;
        maxX = max(maxX,0);
        newOffset.x = clamp(newOffset.x, 0, maxX);
        
        let maxY = contentSizeHeight - scrollViewHeight + self.mainScrollView.adjustedContentInset.bottom;
        newOffset.y = clamp(newOffset.y, 0, maxY);
        
        return newOffset;
    }
    
    private func maintainCurrentPageOnLayoutChange(_ curPageIndex: Int,
                                                   previousLayoutType : FTPageLayout)
    {
        let contentOffset = self.contentOffsetWrtPage(previousLayoutType);
        
        self.updateContentSize();
        let pageFrame = self.pageLayoutHelper.frame(for: curPageIndex);
        let currentDel = self.mainScrollView.scrollViewDelegate;
        self.mainScrollView.scrollViewDelegate = nil;
        if let contorller = self.firstPageController() {
            if(previousLayoutType == .vertical) {
                self.mainScrollView.contentInset = UIEdgeInsets.zero;
                let factor = self.mainScrollView.zoomFactor;
                self.mainScrollView.zoom(1, animate: false, completionBlock: nil);

                self.mainScrollView.setContentOffset(pageFrame.origin, animated: false);
                self.updateContentOffsetPercentage();

                self.setNeedsLayoutForcibly();

                contorller.zoom(scale: factor, animate: false, completionBlock: nil);
                contorller.view.layoutIfNeeded();
                if let scrollView = contorller.scrollView {
                    var newContentOffset = CGPoint.zero;

                    newContentOffset.x = (contentOffset.x * scrollView.contentSize.width);
                    if(newContentOffset.x + scrollView.frame.width > scrollView.contentSize.width) {
                        newContentOffset.x = scrollView.contentSize.width - scrollView.frame.width;
                    }
                    if(newContentOffset.x < 0) {
                        newContentOffset.x = 0;
                    }
                    
                    newContentOffset.y = (contentOffset.y * scrollView.contentSize.height);
                    if(newContentOffset.y + scrollView.frame.height > scrollView.contentSize.height) {
                        newContentOffset.y = scrollView.contentSize.height - scrollView.frame.height;
                    }
                    if(newContentOffset.y < 0) {
                        newContentOffset.y = 0;
                    }
                    
                    scrollView.setContentOffset(newContentOffset, animated: false);
                    self.updateContentOffsetPercentage();
                }
            }
            else {
                let visibleControllers = self.visiblePageViewControllers();
                visibleControllers.forEach { (controller) in
                    controller.setAccessoryViewHeight(0);
                }
                
                let curPageFrame = contorller.contentHolderView?.frame ?? CGRect.zero;
                var offset: CGFloat = 0;
                if let scroll = contorller.scrollView, scroll.frame.height > curPageFrame.height {
                    offset = (scroll.frame.height - curPageFrame.height)*0.5;
                }

                let factor = self.contentScaleInNormalMode;
                contorller.zoom(scale: 1, animate: false, completionBlock: nil);
                self.mainScrollView.zoom(factor, animate: false, completionBlock: nil);
                
                let frame = CGRectScale(pageFrame, factor);
                var newContentOffset = frame.origin;
                newContentOffset.x += (contentOffset.x * frame.size.width);
                
                if(newContentOffset.x + self.mainScrollView.frame.width > self.mainScrollView.contentSize.width) {
                    newContentOffset.x = self.mainScrollView.contentSize.width - self.mainScrollView.frame.width;
                }
                if(newContentOffset.x < 0) {
                    newContentOffset.x = 0;
                }

                newContentOffset.y += (contentOffset.y * frame.size.height);
                newContentOffset.y -= offset;
                if(newContentOffset.y + self.mainScrollView.frame.height > self.mainScrollView.contentSize.height) {
                    newContentOffset.y = self.mainScrollView.contentSize.height - self.mainScrollView.frame.height;
                }
                if(newContentOffset.y < 0) {
                    newContentOffset.y = 0;
                }

                self.mainScrollView.setContentOffset(newContentOffset, animated: false);
                self.updateContentOffsetPercentage();
                self.setNeedsLayoutForcibly();
            }
        }
        self.mainScrollView.scrollViewDelegate = currentDel;
    }
    
    private func contentOffsetWrtPage(_ previousLayout : FTPageLayout) -> CGPoint {
        var contentOffset = self.mainScrollView.contentOffset;
        if let contorller = self.firstPageController() {
            if(previousLayout == .vertical) {
                contentOffset.x -= contorller.view.frame.minX;
                contentOffset.y -= contorller.view.frame.minY;
                contentOffset.x /= contorller.view.frame.width;
                contentOffset.y /= contorller.view.frame.height;
            }
            else if let scrollView = contorller.scrollView {
                contentOffset = scrollView.contentOffset;
                contentOffset.x /= scrollView.contentSize.width;
                contentOffset.y /= scrollView.contentSize.height;
            }
        }
        return contentOffset;
    }
}

extension FTPDFRenderViewController: FTRefreshSelectedItemDelegate {
    func toolbarMode() -> FTScreenMode {
        return self.toolBarState()
    }
    
    
    private func addRefresh(layout : FTPageLayout,scrollView : FTDocumentScrollView) {
        #if !targetEnvironment(macCatalyst)
        let position: [FTRefreshPosition];
        switch layout {
        case .vertical:
            position = [.top,.bottom];
        case .horizontal:
            position = [.left,.right];
        }
        scrollView.setRefreshPositions(position,
                                       delegate: self);
        #endif
    }
    
    func toolBarHeight() -> CGFloat {
        return self.deskToolBarHeight()
    }
    
    @objc func currentToolBarState() -> FTScreenMode {
        if let documentController = self.parent as? FTDocumentRenderViewController {
            return documentController.currentToolBarState()
        }
        return FTScreenMode.normal
    }

    func didSelectItem(_ menuItem: FTAddMenuItemProtocol, insertPagePosition position: FTRefreshPosition?) {
        
        var index: Int = self.pdfDocument.pages().count
        switch position {
        case .top,.left:
            index = 0
        default:
            break
        }
        self.addNewpageMode = FTRefreshMode
       
        switch menuItem.key {
        case .Page:
            self.insertEmptyPage(at: index)
        case .PhotoBackground:
            self.insertingPhotoAsPage = true
            FTPHPicker.shared.presentPhPickerController(from: self, selectionLimit: 1)
        case .PageFromTemplate:
            self.isNewPageFromTemplate = true
            self.showPaperTemplateScreen(source: .addMenu)
        case .ImportDocument:
            self.insertingPhotoAsPage = true
            self.importDocumentClicked(nil)
        case .ScanDocument:
            let scanService = FTScanDocumentService.init(delegate: self);
            scanService.startScanningDocument(onViewController: self);
        case .Camera:
            self.insertingPhotoAsPage = true
            FTImagePicker.shared.showImagePickerController(from: self)
        default:
            break
        }
    }
    
    func didInsertPageFromRefreshView(type: FTPageType) {
        self.addNewpageMode = FTRefreshMode
        if type == .pageFromCamera || type == .photoTemplate {
            self.insertingPhotoAsPage = true
        }
        self.performPageInsertOperation(type)
    }
}

extension FTPDFRenderViewController: FTPHPickerDelegate, FTImagePickerDelegate {
    public func didFinishPicking(results: [PHPickerResult], photoType: PhotoType) {
        if photoType != .photoLibrary {
            return
        }
        FTPHPicker.shared.processResultForUIImages(results: results) { phItems in
            if self.insertingPhotoAsPage {
                self.insertingPhotoAsPage = false
                guard let phItem = phItems.first else {
                    return
                }
                let img = phItem.image
                let item = FTImportItem(item: img, onCompletion: nil)
                self.beginImporting(items: [item])
            } else {
                let images = phItems.map { $0.image }
                self.insert(images, center: .zero, droppedPoint: .zero, source: FTInsertImageSourcePhotos)
            }
        }
    }

    public func didFinishPicking(image: UIImage, picker: UIImagePickerController) {
        self.photosCollectionViewController(self, didFinishPickingPhotos: [image], isCamera: true)
    }
}

extension FTPDFRenderViewController: FTPageLayouterDelegate {
    func yPosition() -> CGFloat {
    #if !targetEnvironment(macCatalyst)
        if self.pageLayoutHelper.layoutType == .vertical
            , self.toolBarState() != .shortCompact {
            return self.deskToolBarHeight();
        }
        return 0;
    #else
        return 0
    #endif
    }
}
