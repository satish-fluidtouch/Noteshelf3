//
//  FTUnsplashViewController.swift
//  FTNewNotebook
//
//  Created by Narayana on 10/03/23.
//

import UIKit
import FTCommon
import Network

class FTUnsplashViewController: FTCoversHeaderController {
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var collectionViewHeightConstraint: NSLayoutConstraint?

    private let cellIdentifier = "FTUnsplashCollectionViewCell"
    private let searchUnSplashCellId = "FTSearchUnsplashCell"
    private let viewModel = FTUnsplashViewModel()
    private var currentPage: Int = 1
    private var searchKey: String = ""
    private var size: CGSize = .zero
    weak var delegate: FTCoverSelectionDelegate?
    private let monitor = FTNetworkPathMonitor()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.shapeTopCorners()
        self.configureNavigationItems(with: "Unsplash")
        self.configureCollectionView()
        // loading indicator to show here
        self.fetchAndUpdateUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.size != self.view.frame.size {
            self.size = self.view.frame.size
            self.collectionView?.collectionViewLayout.invalidateLayout()
            self.updateCollectionView()
            self.collectionView.reloadData()
        }
    }

    private func fetchAndUpdateUI(for page: Int = 1) {
        if !self.searchKey.isEmpty {
            self.title = "Results for \(searchKey)"
        }

        monitor.checkIfInternetIsAvailable { [weak self] status in
            guard let self = self else {
                return
            }
            if status {
                self.viewModel.fetchUnsplash(with: self.searchKey, page: page) { success, error in
                    runInMainThread {
                        if nil == error, success {
                            self.collectionView.reloadData()
                        } else if let err = error {
                            let alertVc = UIAlertController(title: "Error", message: err.localizedDescription, preferredStyle: .alert)
                            alertVc.addAction(UIAlertAction(title: "Ok", style: .default))
                            self.present(alertVc, animated: true)
                        }
                    }
                }
            } else {
                self.showNoInternetConnectionAlert()
            }
        }
    }

    private func showNoInternetConnectionAlert() {
        runInMainThread {
            UIAlertController.showAlert(withTitle: "NoInternetHeader".localized, message: "MakeSureYouAreConnected".localized, from: self, withCompletionHandler: nil)
        }
    }

    private func configureCollectionView() {
        self.collectionView.register(UINib(nibName: "FTUnsplashCollectionViewCell", bundle: currentBundle), forCellWithReuseIdentifier: cellIdentifier)
    }

    private func updateCollectionView() {
        let contentInset: UIEdgeInsets
        let height: CGFloat
        if self.size.width < 400.0 {
            contentInset = FTCovers.Panel.Unsplash.compactContentInset
            height = (FTCovers.Panel.Unsplash.compactCellSize.height * 2.0) + (FTCovers.Panel.Unsplash.lineSpacing) + (FTCovers.Panel.Unsplash.sectionInset * 2.0)
        } else {
            contentInset = FTCovers.Panel.Unsplash.contentInset
            height = (FTCovers.Panel.Unsplash.cellSize.height * 2.0) + (FTCovers.Panel.Unsplash.lineSpacing) + (FTCovers.Panel.Unsplash.sectionInset * 2.0)
        }
        self.collectionViewHeightConstraint?.constant = height
        self.collectionView.contentInset = contentInset
    }

    override func doneTapped() {
        monitor.cancelMonitoring()
        self.delegate?.didTapOnDoneButton()
    }

    override func backButtonTapped() {
        monitor.cancelMonitoring()
        super.backButtonTapped()
    }
}

extension FTUnsplashViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.unsplashItems.count + 1 // Search unsplash
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0 {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: searchUnSplashCellId, for: indexPath) as? FTSearchUnsplashCell else {
                fatalError("Programmer error unable to find FTUnsplashCollectionViewCell")
            }
            cell.delegate = self
            cell.searchUnsplash = { searchText in
                if !searchText.isEmpty {
                    self.viewModel.clearUnsplashItems()
                    self.searchKey = searchText
                    self.fetchAndUpdateUI(for: 1)
                }
            }
            cell.configure()
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? FTUnsplashCollectionViewCell else {
                fatalError("Programmer error unable to find FTUnsplashCollectionViewCell")
            }
            let item = self.viewModel.unsplashItems[indexPath.row - 1]
            cell.configure(with: item, mode: .newNotebook)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let prevVisibleSelCell = collectionView.visibleCells.first(where: { cell in
            cell.isSelected
        }) as? FTUnsplashCollectionViewCell {
            prevVisibleSelCell.isSelected = false
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? FTSearchUnsplashCell {
            cell.searchStarter.becomeFirstResponder()
        } else {
            if let cell = collectionView.cellForItem(at: indexPath) as? FTUnsplashCollectionViewCell {
                cell.isSelected = true
                let item = self.viewModel.unsplashItems[indexPath.row - 1]
                monitor.checkIfInternetIsAvailable { [weak self] status in
                    guard let self = self else {
                        return
                    }
                    if status {
                        Task {
                            if let fulUrl = item.urls?.regular {
                                self.delegate?.didSelectUnsplash(of: fulUrl)
                            }
                        }
                    } else {
                        self.showNoInternetConnectionAlert()
                    }
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        self.collectionView(collectionView, prefetchItemsAt: [indexPath])
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return FTCovers.Panel.Unsplash.itemSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return FTCovers.Panel.Unsplash.lineSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let inset = FTCovers.Panel.Unsplash.sectionInset
        return UIEdgeInsets(top: inset, left: 0.0, bottom: inset, right: 0.0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size: CGSize
        if self.size.width < 400.0 {
            size = FTCovers.Panel.Unsplash.compactCellSize
        } else {
            size = FTCovers.Panel.Unsplash.cellSize
        }
        return size
    }
}

extension FTUnsplashViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard !viewModel.isFetching, let maxItem = indexPaths.max(),
              maxItem.row >= viewModel.unsplashItems.count - 1
        else {
            return
        }
        self.currentPage += 1
        self.fetchAndUpdateUI(for: self.currentPage)
    }
}

extension FTUnsplashViewController: FTSearchUnsplashCellDelegate {
    func getSearchKey() -> String {
        return searchKey
    }
}
