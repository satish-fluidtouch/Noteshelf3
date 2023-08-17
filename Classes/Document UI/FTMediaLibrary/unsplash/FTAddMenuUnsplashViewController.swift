//
//  FTAddMenuUnsplashViewController.swift
//  Noteshelf
//
//  Created by srinivas on 13/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import Combine
import FTStyles
import FTNewNotebook
import FTCommon

protocol FTAddMenuSelectImageProtocal: AnyObject {
    func didSelectImage(_ image: [UIImage], source: FTInsertImageSource)
}

class FTAddMenuUnsplashViewController: UIViewController, UIGestureRecognizerDelegate, FTPopoverPresentable {
    var ftPresentationDelegate = FTPopoverPresentation()

    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var segmentControl: FTSegmentedControl!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var errorStackView: UIStackView!
    
    var subscriptions = Set<AnyCancellable>()
    let viewModel = FTAddMenuUnsplashViewModel()
    let cellIdentifier = "FTUnsplashCollectionViewCell"
    var task: Task<Void, Never>?
    var page: Int = 1
    var categories: [FTMediaCategoryProtocol]?
    weak var imageSelectionDelegate: FTAddMenuSelectImageProtocal?

    var toHideBackBtn: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize = CGSize(width: 320.0, height: 544.0)
        self.backButton.isHidden = toHideBackBtn
        self.addButton.alpha = 0.5
        self.setupCollectionView()
        self.setupSearchBar()
        self.setupBindigs()
        self.setupSegmentController()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if task != nil {
            task?.cancel()
            task = nil
        }
    }
    
    private func setupBindigs() {
        viewModel.errorText = { [weak self] text in
            guard let self = self else { return }
            //UIView.isHidden must be used from main thread only
            self.errorStackView.isHidden = false
            let views = self.errorStackView.subviews
            let label = views[2] as? UILabel
            label?.text = text
        }
        
        viewModel.items.sink { [weak self] items in
            self?.errorStackView.isHidden = true
            self?.collectionView.reloadData()
        }.store(in: &subscriptions)
    }
    
    private func setupCollectionView() {
        collectionView.register(UINib(nibName: "FTUnsplashCollectionViewCell", bundle: Bundle(for: FTCreateNotebookViewController.self)), forCellWithReuseIdentifier: cellIdentifier)
        collectionView.layer.cornerRadius = 10.0
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.prefetchDataSource = self
        collectionView.allowsMultipleSelection = true
        updateAddButtonMode()
    }
    

    private func setupSegmentController() {
        categories = viewModel.fetchSegmentItems()
        let titles = categories?.map { $0.localizedString }
       
        segmentControl.delegate = self
        segmentControl.setTitles(titles!, style: .adaptiveSpace(18))
        segmentControl.textColor = UIColor.appColor(.black70)
        segmentControl.textSelectedColor = UIColor.white
        segmentControl.textFont = UIFont.appFont(for: .medium, with: 13.0)
        segmentControl.textCornerRadius = 10.0
        segmentControl.textBorderWidth = 0.0
        segmentControl.segmentBgColor = UIColor.appColor(.black5)
        segmentControl.selectedSegmentBgColor = UIColor.appColor(.neutral)
        segmentControl.setCover(upDowmSpace: 0, cornerRadius: 10)
        segmentControl.backgroundColor = .clear
    }
    
    @IBAction func tapOnBackButton(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func tapOnAddButton(_ sender: UIButton) {
        if let selectedItemIndexPaths = collectionView.indexPathsForSelectedItems {
            let indices = selectedItemIndexPaths.map { $0.row }
            viewModel.downloadItemAt(indices: indices, { [weak self] images, error in
                guard let self else {
                    return
                }
                if let err = error {
                    UIAlertController.showAlert(withTitle: "Error".localized, message: err.localizedDescription, from: self, withCompletionHandler: nil)
                } else {
                    var controllerToDismiss: UIViewController = self
                    if let navVc = self.navigationController {
                        controllerToDismiss = navVc
                    }
                    controllerToDismiss.dismiss(animated: true, completion: {
                        self.imageSelectionDelegate?.didSelectImage(images, source: FTInsertImageSourceUnSplash)
                    })
                }
            })
        }
    }
}

extension FTAddMenuUnsplashViewController: FTSegmentedControlDelegate {
    
    func segmentedControlSelectedIndex(_ index: Int, animated: Bool, segmentedControl: FTSegmentedControl) {
//        searchBar.resignFirstResponder()
        let segmentsItems = viewModel.fetchSegmentItems()
        let item = segmentsItems[index]
        categoryKey = item.apiImageType
    }
    
    func didEndScrollOfSegments() {
        track("emojis_tab_scrolled", params: [:], screenName: FTScreenNames.noteBookAddNew)
    }
    
    func didTapSegment(_ index: Int) {
      
        debugPrint("didTapSegment index : \(index)")
        self.collectionView.contentOffset = CGPoint(x: 0, y: 0)
        lastSelectedIndex = index
        segmentControl.selectedIndex = index
        searchBar.resignFirstResponder()
        let segmentsItems = viewModel.fetchSegmentItems()
        let item = segmentsItems[index]
        categoryKey = item.apiImageType
        self.searchBar.searchTextField.text = ""
        self.viewModel.searchText.send(categoryKey)
    }
}

// MARK: - Search
extension FTAddMenuUnsplashViewController {
    
    private func setupSearchBar() {
        NotificationCenter.default.publisher(for: UISearchTextField.textDidChangeNotification,
                                             object: searchBar.searchTextField)
        .compactMap({($0.object as? UISearchTextField)?.text})
        .removeDuplicates()
        .debounce(for: 1.0, scheduler: RunLoop.main)
        .sink { [weak self] keyword in
            guard let self = self else { return }
            
            if !keyword.isEmpty {
                self.collectionView.contentOffset = CGPoint(x: 0, y: 0)
                self.segmentControl.hideCoverViewOnSearchStart()
                self.viewModel.searchText.send(keyword)
            } else {
                self.segmentControl.selectedIndex = self.lastSelectedIndex
                self.viewModel.searchText.send(self.categoryKey)
            }
        }.store(in: &subscriptions)
        
        /// initial load
       loadItems()
    }
    
    private func loadItems() {
        self.searchBar.searchTextField.text = ""
        self.collectionView.contentOffset = CGPoint(x: 0, y: 0)
        let category = self.categoryKey
        debugPrint("last selected category \(category)")
        segmentControl.selectedIndex = lastSelectedIndex
        self.viewModel.searchText.send(category)
    }
    
    private func loadMoreItems() {
//        self.searchBar.searchTextField.text = ""
        if task != nil {
            task?.cancel()
            task = nil
        }
        task = Task {
            await viewModel.fetchUnsplash(pageNo: page)
        }
    }
}

// MARK: - Load More
extension FTAddMenuUnsplashViewController: UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
//        debugPrint("isFeteching : \(viewModel.isFeteching.value)")
   
        guard !viewModel.isFeteching.value,
                let maxItem = indexPaths.max(),
              maxItem.row >= viewModel.items.value.count - 1
        else { return }

        debugPrint("prefetchItemsAt...\(maxItem.row) & \(viewModel.items.value.count - 1)")
        page += 1
        loadMoreItems()
    }
}

// MARK: - UICollectionViewDataSource
extension FTAddMenuUnsplashViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.items.value.count
    }
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? FTUnsplashCollectionViewCell else {
            fatalError("Failed deque cell")
        }
       
        let item = viewModel.items.value[indexPath.row]
        cell.configure(with: item)
        
        return cell
    }
}

extension FTAddMenuUnsplashViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let totalSelectedItems = collectionView.indexPathsForSelectedItems {
            if totalSelectedItems.count > 5 {
                collectionView.deselectItem(at: indexPath, animated: true)
                UIAlertController.showAlert(withTitle: "DragItemsCountValidation".localized, message: "", from: self, withCompletionHandler: nil)
            }
        }
        self.updateAddButtonMode()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.updateAddButtonMode()
    }
    
    private func updateAddButtonMode() {
        if let totalSelectedItems = self.collectionView.indexPathsForSelectedItems {
            self.addButton.isEnabled = totalSelectedItems.count > 0
            self.addButton?.alpha = self.addButton.isEnabled ? 1.0 : 0.5
        }
    }
    private func showAlert() {
        let message = "DragItemsCountValidation".localized
         UIAlertController.showAlert(withTitle: message, message: "", from: self, withCompletionHandler: nil)
    }
}

// MARK: - UserDefaults
extension FTAddMenuUnsplashViewController {
    
    private enum Keys: String {
        case lastIndexKey
        case categoryKey
    }
    
    var lastSelectedIndex: Int {
        get {
            UserDefaults.standard.integer(forKey: Keys.lastIndexKey.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.lastIndexKey.rawValue)
        }
    }

    var categoryKey: String {
        get {
            UserDefaults.standard.string(forKey: Keys.categoryKey.rawValue) ?? "Recent"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.categoryKey.rawValue)
        }
    }
}

extension FTAddMenuUnsplashViewController {
    class func showAddMenuUnSplashController(from controller: UIViewController, source: Any, toHideBackBtn: Bool = false) -> FTAddMenuUnsplashViewController {
        let storyboard = UIStoryboard.init(name: "FTDocumentEntity", bundle: nil)
        guard let unsplashViewController = storyboard.instantiateViewController(withIdentifier: "FTAddMenuUnsplashViewController") as? FTAddMenuUnsplashViewController else {
            fatalError("Programmer error, FTAddMenuUnsplashViewController not found")
        }

        unsplashViewController.toHideBackBtn = toHideBackBtn
        unsplashViewController.view.backgroundColor = UIColor.appColor(.popoverBgColor)
        unsplashViewController.ftPresentationDelegate.source = source as AnyObject
        controller.ftPresentPopover(vcToPresent: unsplashViewController, contentSize: AddMenuType.media.contentSize, hideNavBar: true)
        return unsplashViewController
    }
}
