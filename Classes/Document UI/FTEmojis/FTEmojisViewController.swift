//
//  FTEmojisViewController.swift
//  FTAddOperations
//
//  Created by Siva on 09/06/20.
//  Copyright © 2020 Siva. All rights reserved.
//

import UIKit
import FTStyles
import Combine
import FTCommon

/// TODOs :
/// compact mode,
/// dark mode, localization

@objc protocol StickerSelectionDelegate: NSObjectProtocol {
    func stickerSelected(_ stickerImage: UIImage?, emojiID: UInt)
    @objc optional func isLandscapeNotebook() -> Bool
}

class FTEmojisViewController: UIViewController,  FTPopoverPresentable {
    var ftPresentationDelegate = FTPopoverPresentation()

    @IBOutlet private weak var segmentedControl: FTSegmentedControl!
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    
    weak var delegate: StickerSelectionDelegate?
    let emojiesManager = FTEmojiesManager()
    var subscriptions = Set<AnyCancellable>()
    var shouldUpdateSegmentedIndex: Bool = false
    var toHideBackBtn: Bool = false

    private static let cellIdentifier = "emojicell"
    private var sections = [FTEmojiesCategory]()
    private var sectionsMaster = [FTEmojiesCategory]()
    private var emojis = [FTEmojisItem]()
    private var scrollTableviewOnCategorySegmentChange: Bool = false
    private var didSearchStarted: Bool = false
    private var contentSize = CGSize(width: 320.0, height: 544.0)
    
    var isFromCentralPanel : FTSourceScreenType = .Others

    private var selectedSegmentIndex: Int {
        get {
            let index = UserDefaults.standard.integer(forKey: "SegmentIndex")
            return index
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "SegmentIndex")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.backButton.isHidden = self.toHideBackBtn
        self.setupCollectionView()
        self.setupSegmentedControl()
        self.setupSearchBarTypingAction()
        self.preferredContentSize = contentSize
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if isFromCentralPanel == .centerPanel {
            if let window = self.view.window {
                NotificationCenter.default.post(name: .centralPanelPopUpDismiss, object: ["sourceType":FTToolbarPopoverScreen.emoji,"window":window])
            }
        }
    }
    
    @IBAction func tapOnBackButton(_ sender: UIButton) {
        guard let _ = navigationController?.popViewController(animated: true) else {
            // ll be executed during emoji edit and back tap
            self.dismiss(animated: true)
            return
        }
    }

    private func setupCollectionView() {
        sectionsMaster = emojiesManager.getCategoryList()
        self.sections = sectionsMaster
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(FTEmojiCollectionViewCell1.self, forCellWithReuseIdentifier: Self.cellIdentifier)
        collectionView.register(FTEmojiCategoryHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: FTEmojiCategoryHeaderView.identifier)
    }
    
    override func viewDidLayoutSubviews() {
        if let frame = segmentedControl?.bounds {
            segmentedControl?.scrollView.frame = frame
        }
    }
        
    //MARK:- Presentation
    class func showAsPopover(fromSourceView sourceView: Any,
                             overViewController viewController: UIViewController,
                             withDelegate delegate: StickerSelectionDelegate, toHideBackBtn: Bool = false) {
        let storyboard = UIStoryboard.init(name: "FTDocumentEntity", bundle: nil);
        guard let stickerSelectionViewController  = storyboard.instantiateViewController(withIdentifier: "FTEmojisViewController") as? FTEmojisViewController else {
            fatalError("Programmer error, Couldnot find FTEmojisViewController")
        }
        stickerSelectionViewController.delegate = delegate
        stickerSelectionViewController.isFromCentralPanel = .centerPanel
        stickerSelectionViewController.toHideBackBtn = toHideBackBtn
        stickerSelectionViewController.ftPresentationDelegate.source = sourceView as AnyObject
        viewController.ftPresentPopover(vcToPresent: stickerSelectionViewController, contentSize: stickerSelectionViewController.contentSize, hideNavBar: true)
     }
}

//MARK:- FTSegmentedControlDelegate
extension FTEmojisViewController: FTSegmentedControlDelegate {
    private func setupSegmentedControl() {
        
        self.sections = sectionsMaster
        let titles = sectionsMaster.map{ $0.title.localized }

        segmentedControl?.delegate = self
        segmentedControl?.setTitles(titles, style: .adaptiveSpace(18))
        segmentedControl.textColor = UIColor.appColor(.black70)
        segmentedControl.textSelectedColor = UIColor.white
        segmentedControl.textFont = UIFont.appFont(for: .medium, with: 13.0)
        segmentedControl.textCornerRadius = 10.0
        segmentedControl.textBorderWidth = 0.0
        segmentedControl.segmentBgColor = UIColor.appColor(.black5)
        segmentedControl.selectedSegmentBgColor = UIColor.appColor(.neutral)
        segmentedControl.setCover(upDowmSpace: 0, cornerRadius: 10)
        segmentedControl.backgroundColor = .clear
        segmentedControl.selectedIndex = selectedSegmentIndex
    }
    
    public func segmentedControlSelectedIndex(_ index: Int, animated: Bool, segmentedControl: FTSegmentedControl) {
        if didSearchStarted {
            didSearchStarted = false
            searchBar.text = ""
        }

        collectionView.reloadData()

        if collectionView.isScrolling == false {
            runInMainThread(0.01) {
                if let attributes = self.collectionView.layoutAttributesForSupplementaryElement(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: index)) {
                    var offsetY = attributes.frame.origin.y - self.collectionView.contentInset.top
                    offsetY -= self.collectionView.safeAreaInsets.top
                    self.collectionView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: animated)
                }
            }
        }
    }
    
    public func didEndScrollOfSegments() {
        track("emojis_tab_scrolled", params: [:], screenName: FTScreenNames.noteBookAddNew)
    }
    
    func didTapSegment(_ index: Int) {
        self.selectedSegmentIndex = index
        FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.nbk_addmenu_emojis_category_tap)
    }
}

// MARK: - Search UISearchBarDelegate
extension FTEmojisViewController {
    
    private func setupSearchBarTypingAction() {
        NotificationCenter.default
            .publisher(for: UISearchTextField.textDidChangeNotification, object: searchBar.searchTextField)
            .compactMap{($0.object as? UISearchTextField)?.text}
            .removeDuplicates()
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] keyword in
                debugPrint(keyword)
                guard let self = self else { return }
                self.loadEmojies(for: keyword)
            }.store(in: &subscriptions)
        // to detect search tap in keyboard and to dismiss keyboard
        self.searchBar.searchTextField.delegate = self
    }
    
    private func loadEmojies(for searchKey: String = "") {
        guard !searchKey.isEmpty else {
            self.sections = sectionsMaster
            self.collectionView.reloadData()
            self.segmentedControl?.selectedIndex = selectedSegmentIndex
            return
        }
        self.didSearchStarted = true
        self.segmentedControl?.hideCoverViewOnSearchStart()
        collectionView.contentOffset = CGPoint(x: 0, y: 0)

        let items = self.sectionsMaster.map({$0}).filter({$0.title.localized != "Recents".localized }).map({$0.items}).reduce([], +)

        let emojies =  items.filter({ (item) -> Bool in
            return item.keyword.lowercased().contains(searchKey.lowercased())
        })
        self.emojis = emojies
        self.collectionView.reloadData()
        FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.nbk_addmenu_emojis_search_tap)
    }
}

// MARK: UISearchBarDelegate
extension FTEmojisViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // This is just to hide keyboard, search is handled in publisher already(setupSearchBarTypingAction)
        if let text = textField.text, !text.isEmpty {
            textField.resignFirstResponder()
        }
        return true
    }
}

// MARK: UICollectionViewDataSource
extension FTEmojisViewController: UICollectionViewDelegate, UICollectionViewDataSource,
                                    UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return didSearchStarted ? 1 : sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return !didSearchStarted ? sections[section].items.count : emojis.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.cellIdentifier, for: indexPath) as? FTEmojiCollectionViewCell1 else {
            fatalError("Failed deque cell")
        }
        
        if !didSearchStarted {
            let item = sections[indexPath.section].items[indexPath.row]
            cell.emojisItem = item
        } else {
            let item = emojis[indexPath.row]
            cell.emojisItem = item
        }
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: FTEmojiCategoryHeaderView.identifier, for: indexPath) as! FTEmojiCategoryHeaderView
        
        if !didSearchStarted {
            let section = sections[indexPath.section]
            header.configure(name: section.title.localized)
        } else {
            header.configure(name: "")
        }
       
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: didSearchStarted ? 0 : 40)
    }

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let emojiItem: FTEmojisItem
        if !didSearchStarted {
            let section = sections[indexPath.section]
            emojiItem = section.items[indexPath.row]
        } else {
            emojiItem = emojis[indexPath.row]
        }
        emojiesManager.saveEmojiItemIntoUserDefaults(emojiItem: emojiItem)
        let emojiText = emojiItem.emojiSymbol as String
        let emojiImage = emojiesManager.image(forEmojiString: emojiText, size: 32)
        delegate?.stickerSelected(emojiImage, emojiID: UInt(emojiText.hash))
        FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.nbk_addmenu_emojis_emoji_tap)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: 34, height: 34)
    }
}


extension FTEmojisViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if  !scrollView.isDragging {
            return
        }
        
        let indexPath = collectionView.indexPathForItem(at: scrollView.contentOffset)
                
        guard let indexPath = indexPath else {
            let visibleSections = collectionView.indexPathsForVisibleItems.map { $0.section}
            if let section = visibleSections.min() {
                selectedSegmentIndex = section
                if segmentedControl?.selectedIndex != section {
                    segmentedControl?.selectedIndex = section
                }
            }
            return
        }
        
        let section = indexPath.section
        selectedSegmentIndex = section
        if segmentedControl?.selectedIndex != section {
            segmentedControl?.selectedIndex = section
        }
    }
}
