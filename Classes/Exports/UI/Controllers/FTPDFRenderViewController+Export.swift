//
//  FTPDFRenderViewController+Export.swift
//  Noteshelf
//
//  Created by Siva on 18/01/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import FTCommon
import UIKit

 protocol FTShareBeginnerDelegate:  AnyObject {
     func didSelectShareOption(option: FTShareOption)
}

extension FTPDFRenderViewController {
    @objc func showShareOptions(with sourceView: FTCenterToolSourceItem) {
        prepareShareInfo { [weak self] shareInfo in
            guard let self = self else { return }
            let shareHostingVc = FTShareHostingController.showAsPopover(from: self, source: sourceView, info: shareInfo)
            shareHostingVc.delegate = self
        }
    }

    func prepareShareInfo(completion: @escaping (FTShareOptionsInfo) -> Void) {
        var currentPageThumbnail: UIImage?
        var bookCover: UIImage?

        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        getPreview(for: FTShareOption.currentPage) { img in
            currentPageThumbnail = img ?? UIImage()
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        getPreview(for: FTShareOption.allPages) { img in
            bookCover = img ?? UIImage()
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            let bookHasStandardCover: Bool = (self.pdfDocument.pages().first?.isCover ?? false)
            let model = FTShareOptionsInfo(
                currentPageThumbnail: currentPageThumbnail ?? UIImage(),
                bookCover: bookCover ?? UIImage(),
                currentPageNumber: self.currentlyVisiblePage()?.pageIndex() ?? 0,
                allPagesCount: self.numberOfPages(),bookHasStandardCover: bookHasStandardCover
            )
            completion(model)
        }
    }

    //UIAdaptivePresentationControllerDelegate
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

extension FTPDFRenderViewController: FTShareBeginnerDelegate {
    func didSelectShareOption(option: FTShareOption) {
        if option != .selectPages {
            var selectedPages: [FTPageProtocol] = []
            if option == .currentPage, let currentPage = self.currentlyVisiblePage() {
                selectedPages.append(currentPage)
            } else if option == .allPages,let page = self.pdfDocument.pages().first {
                selectedPages.append(page)
            }
            if let coordinator = self.getShareInfo(using: option), let controller = coordinator.presentingVc {
                var bookHasStandardCover: Bool = false
                if option == .allPages, let firstPage = selectedPages.first {
                    bookHasStandardCover = firstPage.isCover
                }
                FTShareFormatHostingController.presentAsFormsheet(over: controller, using: coordinator, option: option, pages: selectedPages,bookHasStandardCover: bookHasStandardCover)
            }
        } else {
            self.didTapOnSelectPages()
        }
    }

    func getShareInfo(using option: FTShareOption) -> FTShareCoordinator? {
        if let shelfItem = self.currentShelfItemInShelfItemsViewController() {
            var reqPages: [FTPageProtocol] = []
            if let currentPage = self.currentlyVisiblePage(), option == .currentPage {
                reqPages = [currentPage]
            } else if option == .allPages {
                reqPages = self.pdfDocument.pages()
            }
            let shareInfo = FTShareCoordinator(shelfItems: [shelfItem], pages: reqPages, presentingController: self)
            return shareInfo
        }
        return nil
    }

    func didTapOnSelectPages() {
        let vc = FTFinderViewController.instantiate(fromStoryboard: .finder)
        vc.configureData(forDocument: self.pdfDocument as! FTThumbnailableCollection, exportInfo: nil, delegate: nil, searchOptions: FTFinderSearchOptions())
        vc.mode = .selectPages
        vc.pdfDelegate = self
        self.present(vc, animated: true)
    }

    func getPreview(for option: FTShareOption, onCompletion: @escaping (UIImage?) -> Void) {
        if option == .currentPage {
            if let currentPage = self.currentlyVisiblePage() {
                currentPage.thumbnail()?.thumbnailImage(onUpdate: { img, _ in
                    onCompletion(img)
                })
            }
        } else if option == .allPages {
            if let pageFirst = self.pdfDocument.pages().first {
                pageFirst.thumbnail()?.thumbnailImage(onUpdate: { img, str in
                    onCompletion(img)
                })
            }
        } else {
            // Some pages to be handled
            onCompletion(nil)
        }
    }
}
