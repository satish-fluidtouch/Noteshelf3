//
//  FTDocumentPagesController.swift
//  Noteshelf3
//
//  Created by Narayana on 10/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTDocumentPagesController: UIViewController {
    @IBOutlet private weak var collectionView: UICollectionView!
    
    private var pages: [FTThumbnailable] = []
    private var cellSize = CGSize(width: 152, height: 204)
    private let extraCellPadding: CGFloat = 30

    weak var delegate: FTPageSelectionDelegate?
    weak var document: FTThumbnailableCollection? {
        didSet {
            self.pages = self.document?.documentPages() ?? []
            self.collectionView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureCollectionView()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if self.isRegularClass() {
            self.cellSize = CGSize(width: 152, height: 204)
        } else {
            self.cellSize = CGSize(width: 144, height: 176)
        }
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
}

private extension FTDocumentPagesController {
    func configureCollectionView() {
        self.collectionView.allowsMultipleSelection = false
        self.collectionView.register(UINib(nibName: "FTFinderThumbnailViewCell", bundle: nil), forCellWithReuseIdentifier: "CollectionViewCellPDFFinderPage")
        (self.collectionView.collectionViewLayout as? FTFinderCollectionViewFlowLayout)?.sectionHeadersPinToVisibleBounds = true
        self.collectionView.contentInset = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
    }

    var contentInset: UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 24, bottom: 22, right: 24)
    }

     func horizontalSpacing() -> CGFloat {
        var expectedSpacing: CGFloat = 0
        let cellWidth: CGFloat = self.cellSize.width
        var availableWidth = self.collectionView.frame.width - CGFloat(self.contentInset.left * 2)
        var cellCount = Int(availableWidth / cellWidth)
        availableWidth = availableWidth - CGFloat((cellCount-1) * Int(10))
        cellCount = Int(availableWidth / cellWidth)

        availableWidth = self.collectionView.frame.width - CGFloat(self.contentInset.left * 2)
        if cellCount > 1{
            expectedSpacing = (availableWidth - CGFloat(cellCount * Int(cellWidth))) / CGFloat((cellCount-1))
        }
        else{
            expectedSpacing = 10
        }
        return expectedSpacing
    }
}

extension FTDocumentPagesController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.pages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCellPDFFinderPage", for: indexPath) as? FTFinderThumbnailViewCell, indexPath.row < pages.count else {
            fatalError("Programmer error - could not find FTFinderThumbnailViewCell")
        }
        let page = self.pages[indexPath.row]
        cell.page = page
        cell.editing = true
        let isCellSelected = self.pages.contains(where: { element -> Bool in
            return element.uuid == cell.page?.uuid
        })
        cell.selectionBadge?.isHidden = true
        cell.setIsSelected(isCellSelected)
//        if let currentPage = self.delegate?.currentPage(in: self), currentPage.uuid == page.uuid, self.mode == .none {
//            collectionViewCell.setAsCurrentVisiblePage()
//        }
        cell.buttonBookmark?.tag = indexPath.item
        cell.buttonBookmark?.isSelected = false;
        let imageName = "bookmark.fill"
        cell.buttonBookmark?.setImage(UIImage(systemName: imageName), for: .normal)
        let bookmarkColor = (!page.bookmarkColor.isEmpty) ? UIColor(hexString: page.bookmarkColor) : .appColor(.gray9)
        cell.buttonBookmark?.tintColor = page.isBookmarked ? bookmarkColor : .appColor(.gray9)
        let size = AVMakeRect(aspectRatio: page.pdfPageRect.size, insideRect: CGRect(origin: CGPoint.zero, size: self.cellSize)).size
        cell.pdfSize = size;
        cell.pageSize = self.cellSize
        cell.labelPageNumber?.text = "\(page.pageIndex() + 1)";
        cell.setThumbnailImage(usingPage: page);
        cell.shouldShowVerticalDivider = self.view.frame.width <= supplimentaryFinderVcWidth
        cell.buttonBookmark?.tag = indexPath.item
        cell.updateTagsPill()
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let page = self.pages[indexPath.item] as? FTNoteshelfPage {
            if let collectionViewCell = collectionView.cellForItem(at: indexPath) as? FTFinderThumbnailViewCell {
                collectionViewCell.setIsSelected(true)
            }
            self.delegate?.didSelect(page: page)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if collectionView == self.collectionView, indexPath.item < self.pages.count  {
            let page = self.pages[indexPath.item]
            page.thumbnail()?.cancelThumbnailGeneration()
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
         return 24
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return self.horizontalSpacing()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return self.contentInset
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let page = self.pages[indexPath.item]
        let size = AVMakeRect(aspectRatio: page.pdfPageRect.size, insideRect: CGRect.init(origin: CGPoint.zero, size: self.cellSize)).size
        return CGSize(width: self.cellSize.width, height: size.height + extraCellPadding)
    }
}
