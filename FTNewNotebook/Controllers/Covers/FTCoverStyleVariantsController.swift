//
//  FTCoverStyleVariantsController.swift
//  FTNewNotebook
//
//  Created by Narayana on 24/02/23.
//

import UIKit

class FTCoverStyleVariantsController: UIViewController {
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var collectionViewWidthConstraint: NSLayoutConstraint?

    private let cellReuseId = "FTCoverStyleCollectionViewCell"
    private var size: CGSize = .zero

    var variantsData: [FTCoverVariantModel] = [] {
        didSet {
            self.relayoutCollectionView()
            self.collectionView.reloadData()
        }
    }
    
    weak var variantDelegate: FTCoverVariantDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.view.frame.size != size {
            self.relayoutCollectionView()
        }
    }

    private func relayoutCollectionView() {
        let variantCount = self.variantsData.count
        let totalItemsWidth = FTCovers.Panel.variantSize.width * CGFloat(variantCount)
        let totalItemSpacing = FTCovers.Panel.variantSpacing * (CGFloat(variantCount) - 1)
        var inset = FTCovers.Panel.SectionInset.regular
        if !self.isRegularClass() {
            inset = FTCovers.Panel.SectionInset.compact
        }
        var reqWidth = totalItemsWidth + totalItemSpacing + (2 * inset)
        if reqWidth > self.view.frame.width {
            reqWidth = self.view.frame.width
        }
        self.collectionViewWidthConstraint?.constant = reqWidth
    }
}

extension FTCoverStyleVariantsController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.variantsData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseId, for: indexPath) as? FTCoverStyleCollectionViewCell else {
            fatalError("Programmer error")
        }
        let variantModel = self.variantsData[indexPath.row]
        cell.configure(with: variantModel.imageName, isSelected: false)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? FTCoverStyleCollectionViewCell {
            let variantModel = self.variantsData[indexPath.row]
            self.variantDelegate?.didSelectVariant(variantModel.name)
            cell.isSelected = true
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return FTCovers.Panel.variantSize
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return FTCovers.Panel.variantSpacing
    }
}

extension FTCoverStyleVariantsController: FTCoversScrollDelegate {
    func didScrollToSection(_ section: Int) {
        if !self.variantsData.isEmpty {
            self.collectionView.selectItem(at: IndexPath(row: section, section: 0), animated: true, scrollPosition: .centeredVertically)
        }
    }
}
