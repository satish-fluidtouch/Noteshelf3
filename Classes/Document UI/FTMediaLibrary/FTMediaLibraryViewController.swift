//
//  FTClipartViewController.swift
//  FTAddOperations
//
//  Created by Siva Kumar Reddy on 25/06/20.
//  Copyright © 2020 Siva. All rights reserved.
//

import UIKit
import SDWebImage
import MobileCoreServices
import FTNewNotebook

private let PIXABAY_SEGMENTED_INDEX_KEY = "kPixabaySelectedSegmentIndex"
private let UNSPLASH_SEGMENTED_INDEX_KEY = "kUnsplashSelectedSegmentIndex"

enum MediaSource: String {
    case pixabay, unSplash
    var eventName : String {
        let value: String
        if self == .pixabay {
            value = FTNotebookEventTracker.nbk_addmenu_pixabay_imag_tap
        } else  {
            value = FTNotebookEventTracker.nbk_addmenu_unsplash_image_tap
        }
        return value
    }
}

enum MediaCellTypes: String {
    case normal, recent, editing, norecent, empty, noInternet, noRecords
}

protocol FTMediaLibrarySelectionDelegate: AnyObject {
    func mediaLibraryViewController(_ mediaLibraryViewController: FTMediaLibraryViewController, didSelect mediaImage: UIImage, source: FTInsertImageSource)
}

class FTMediaLibraryViewController: UIViewController, FTPopoverPresentable {
    var ftPresentationDelegate = FTPopoverPresentation()
    
    fileprivate let localProvider = FTLocalMediaLibraryProvider()
    weak var delegate: FTMediaLibrarySelectionDelegate?
    private let themeTintColor = FTShelfThemeStyle.defaultTheme().tintColor;
    private var mediaLibraryDataSource: FTMediaLibraryDataSource?
    private let manager = FTMediaLibraryManager()
    fileprivate let clipartFilter = FTPixabayClipartFilter()

    @IBOutlet private weak var backButton: UIButton!

    var page: Int = 1
    var searchText: String = ""
    
    @IBOutlet fileprivate weak var collectionView: UICollectionView?
    @IBOutlet var categoriesContainerView: UIView?
    @IBOutlet fileprivate var searchBar: UISearchBar?
    @IBOutlet private weak var titleLabel: UILabel!

    private var shouldHideBackButton: Bool = false
    var segmentedControl: FTSegmentedControl?
    
    var recentMediaArray: [FTMediaLibraryModel]?
    var isUnSplashItemsSorted = false
    var sourceType : FTSourceScreenType = .Others
    var mediaSource: MediaSource = .pixabay {
        didSet {
            localProvider.mediaType = mediaSource
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if mediaSource == .pixabay {
            self.titleLabel.text = "Pixabay"
        } else {
            self.titleLabel.text = "Unsplash"
        }
        if shouldHideBackButton {
            backButton.isHidden = true
        }
        self.view.backgroundColor = UIColor.appColor(.popoverBgColor)
        self.preferredContentSize = CGSize(width: 320.0, height: 544.0)

        mediaLibraryDataSource = FTMediaLibraryDataSource.init(with: collectionView, viewController: self)
        mediaLibraryDataSource?.delegate = self
        mediaLibraryDataSource?.localProvider = localProvider
        configureViewBasedOnLastState()
        // Do any additional setup after loading the view.
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (_) in
            self.mediaLibraryDataSource?.layout.invalidateLayout()
        })
    }
    override func viewDidLayoutSubviews() {
            if let frame = categoriesContainerView?.bounds {
                segmentedControl?.scrollView.frame = frame
                }
        }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if sourceType == .centerPanel {
            let source: FTToolbarPopoverScreen = mediaSource == .pixabay ? .pixabay : .unsplash
            if let window = self.view.window {
                NotificationCenter.default.post(name: .centralPanelPopUpDismiss, object: ["sourceType":source,"window":window])
            }
        }
    }
    
    deinit {
           #if DEBUG
               debugPrint("deinit \(self.classForCoder)");
           #endif
       }
    
    private func configureViewBasedOnLastState() {
        let lastState = lastSelectedCategoryState()
        if lastState == 0 {
            DispatchQueue.global(qos: .background).async {
                self.getRecentMediaLibraryItems()
                DispatchQueue.main.async {
                    if self.recentMediaArray?.count == 0 {
                        switch self.mediaSource {
                        case .pixabay:
                            UserDefaults.standard.setValue(2, forKey: PIXABAY_SEGMENTED_INDEX_KEY)
                        case .unSplash:
                            UserDefaults.standard.setValue(2, forKey: UNSPLASH_SEGMENTED_INDEX_KEY)
                        }
                    }

                    DispatchQueue.global(qos: .background).async {
                        self.fetchMediaLibraryBySelectedSource()
                        DispatchQueue.main.async {
                            self.categoriesContainerView?.subviews.forEach { $0.removeFromSuperview() }
                            self.configureSegmentedControl()
                        }
                    }
                }
            }
        }
        else {
            
            DispatchQueue.global(qos: .background).async {
                self.fetchMediaLibraryBySelectedSource()
                DispatchQueue.main.async {
                    self.categoriesContainerView?.subviews.forEach { $0.removeFromSuperview() }
                    self.configureSegmentedControl()
                }
            }
        }
        
    }
    
    fileprivate lazy var pixabaySegmentedItems : [FTMediaCategoryProtocol] = {
        var arItems = [FTMediaCategoryProtocol]()
        arItems.append(RecentSegmentItem())
        arItems.append(PhotosSegmentItem())
        arItems.append(VectorsSegmentItem())
        arItems.append(IllustrationSegmentItem())
        return arItems
    }()
    
    fileprivate lazy var unSplashSegmentedItems : [FTMediaCategoryProtocol] = {
        var arItems = [FTMediaCategoryProtocol]()
        arItems.append(USWallpapersSegmentItem())
        arItems.append(USTravelSegmentItem())
        arItems.append(USNatureSegmentItem())
        arItems.append(USTexturesSegmentItem())
        arItems.append(USBusinessSegmentItem())
        arItems.append(USTechnologySegmentItem())
        arItems.append(USAnimalsSegmentItem())
        arItems.append(USInteriorsSegmentItem())
        arItems.append(USFoodSegmentItem())
        arItems.append(USAthleticsSegmentItem())
        arItems.append(USHealthSegmentItem())
        arItems.append(USFilmSegmentItem())
        arItems.append(USFashionSegmentItem())
        arItems.append(USArtsSegmentItem())
        arItems.append(USHistorySegmentItem())
        return arItems
    }()
    
    fileprivate lazy var unSplashFixedSegmentedItems : [FTMediaCategoryProtocol] = {
        var arItems = [FTMediaCategoryProtocol]()
        arItems.append(USRecentSegmentItem())
        arItems.append(USFeaturedSegmentItem())
        return arItems
    }()
    
    private func configureSegmentedControl() {
        let categoriesSegmentedControl = FTSegmentedControl.init(frame: categoriesContainerView!.bounds)
        categoriesSegmentedControl.backgroundColor = .clear
        
        let titles: [String]
        switch mediaSource {
        case .pixabay:
            titles = pixabaySegmentedItems.map {$0.localizedString}
        case .unSplash:
            if  !isUnSplashItemsSorted {
                isUnSplashItemsSorted = true
                let sort = unSplashSegmentedItems.sorted { $0.localizedString.lowercased() < $1.localizedString.lowercased() }
                unSplashFixedSegmentedItems += sort
                unSplashSegmentedItems.removeAll()
                for(index, var  item) in unSplashFixedSegmentedItems.enumerated() {
                            item.index = index
                            unSplashSegmentedItems.append(item)
                        }
            }
        
            titles = unSplashSegmentedItems.map {$0.localizedString}
        }
        let lastState = lastSelectedCategoryState()
        categoriesSegmentedControl.tag = 2
        categoriesSegmentedControl.delegate = self
        categoriesSegmentedControl.setTitles(titles, style: .adaptiveSpace(19))
        categoriesSegmentedControl.textColor = UIColor.appColor(.black70)
        categoriesSegmentedControl.textSelectedColor = .white
        categoriesSegmentedControl.segmentBgColor = UIColor.appColor(.black5)
        categoriesSegmentedControl.selectedSegmentBgColor = UIColor.appColor(.neutral)
        categoriesSegmentedControl.textFont = UIFont.appFont(for: .medium, with: 13.0)
        categoriesSegmentedControl.setCover(upDowmSpace: 0, cornerRadius: 10)
        categoriesSegmentedControl.selectedIndex = lastState
        categoriesSegmentedControl.textCornerRadius = 10.0
        categoriesSegmentedControl.textBorderWidth = 0.0

        self.segmentedControl = categoriesSegmentedControl
        categoriesContainerView?.addSubview(categoriesSegmentedControl)
    }
    
    private func loadData(mediaLibraryArray: [FTMediaLibraryModel]) {
        self.mediaLibraryDataSource?.isLoading = false
        if mediaLibraryArray.isEmpty {
            self.mediaLibraryDataSource?.isLoading = true
        }
        self.mediaLibraryDataSource?.mediaLibraryArray += mediaLibraryArray
        if self.mediaLibraryDataSource?.mediaLibraryArray.count == 0 {
            self.mediaLibraryDataSource?.isLoading = true
            self.mediaLibraryDataSource?.cellType = .noRecords
            self.mediaLibraryDataSource?.refreshUI()
        }
    }
    
    private  func lastSelectedCategorySegment() -> String? {
        switch mediaSource {
        case .pixabay:
            let selectedTab: FTMediaCategoryProtocol?
            let lastState = UserDefaults.standard.object(forKey: PIXABAY_SEGMENTED_INDEX_KEY) as? Int ?? 1
            selectedTab = pixabaySegmentedItems.filter {$0.index == lastState}.last
            return selectedTab?.apiImageType
        case .unSplash:
            let selectedTab: FTMediaCategoryProtocol?
            let lastState = UserDefaults.standard.object(forKey: UNSPLASH_SEGMENTED_INDEX_KEY) as? Int ?? 1
            if  !isUnSplashItemsSorted {
                     isUnSplashItemsSorted = true
                     let sort = unSplashSegmentedItems.sorted { $0.localizedString.lowercased() < $1.localizedString.lowercased() }
                     unSplashFixedSegmentedItems += sort
                     unSplashSegmentedItems.removeAll()
                     for(index, var  item) in unSplashFixedSegmentedItems.enumerated() {
                                 item.index = index
                                 unSplashSegmentedItems.append(item)
                             }
                 }
            selectedTab = unSplashSegmentedItems.filter {$0.index == lastState}.last
            return selectedTab?.apiImageType
        }
    }
    
    private func lastSelectedCategoryState() -> Int {
        let lastState: Int
        switch mediaSource {
        case .pixabay:
            lastState = UserDefaults.standard.object(forKey: PIXABAY_SEGMENTED_INDEX_KEY) as? Int ?? 1
        case .unSplash:
            lastState = UserDefaults.standard.object(forKey: UNSPLASH_SEGMENTED_INDEX_KEY) as? Int ?? 1
        }
        
        return lastState
    }
    
    //MARK:- API Calls
    private func fetchMediaLibraryBySelectedSource()  {
        mediaLibraryDataSource?.isLoading = false
        switch mediaSource {
        case .pixabay:
            fetchPixabayData()
        case .unSplash:
            fetchUnSplashData()
        }
    }
    
    private func fetchPixabayData()  {
        self.mediaLibraryDataSource?.cellType = .normal
        let lastState = lastSelectedCategoryState()
        if lastState == 0 && searchText.isEmpty {
            DispatchQueue.global(qos: .background).async {
                self.getRecentMediaLibraryItems()
            }
            
            return
        }
        
        if let category = lastSelectedCategorySegment() {
            manager.searchPixabay(type: FTPixabayResponseModel.self, service: FTPixabayPostService.search(query: searchText, imageType: category, sort: .popular, amount: 25, page: page)) { response in
                switch response {
                case let .successWith(posts):
                    let mediaLibraryArray = posts.hits.map { $0.asOpenMediaLibrary() }
                    let filtered = self.clipartFilter.filterClipart(mediaLibraryArray)
                    DispatchQueue.main.async {
                        if self.segmentedControl?.selectedIndex == 1 { // Only for photos tab in pixabey segment spacing is set as 1
                            self.mediaLibraryDataSource?.minimumColumnSpacing = 1.0
                            self.mediaLibraryDataSource?.minimumInterItemSpacing = 1.0
                        }else{
                            self.mediaLibraryDataSource?.minimumColumnSpacing = 12.0
                            self.mediaLibraryDataSource?.minimumInterItemSpacing = 12.0
                        }
                        self.loadData(mediaLibraryArray: filtered)
                    }
                case let .failureWith(error):
                    print(error)
                    DispatchQueue.main.async {
                        if error != .requestCancelled {
                        self.mediaLibraryDataSource?.isLoading = true
                            self.mediaLibraryDataSource?.collectionView.reloadData()

                        }
                        if error == .noInternetConnection {
                            self.mediaLibraryDataSource?.cellType = .noInternet
                            self.mediaLibraryDataSource?.refreshUI()
                        }
                    }
                }
            }
        }
    }
    
    private func fetchUnSplashData()  {
        self.mediaLibraryDataSource?.cellType = .normal
        let lastState = lastSelectedCategoryState()
        if lastState == 0 && searchText.isEmpty {
            getRecentMediaLibraryItems()
            return
        }
        
        if let category = lastSelectedCategorySegment() {
            let str = !searchText.isEmpty ?  searchText : category
            manager.searchUnSplash(type: FTUnSplashResponse.self, service: FTUnsplashPostService.search(query:  str, sort: .revelance, amount: 25, page: page)) { response in
                switch response {
                case let .successWith(posts):
                    let mediaLibraryArray = posts.results.map { $0.asOpenClipart1() }
                    let filtered = self.clipartFilter.filterUnSplash(mediaLibraryArray)
                    DispatchQueue.main.async {
                        self.loadData(mediaLibraryArray: filtered)
                    }
                case let .failureWith(error):
                    print(error)
                    DispatchQueue.main.async {
                        if error != .requestCancelled {
                        self.mediaLibraryDataSource?.isLoading = true
                            self.mediaLibraryDataSource?.collectionView.reloadData()

                        }
                        if error == .noInternetConnection {
                            self.mediaLibraryDataSource?.cellType = .noInternet
                            self.mediaLibraryDataSource?.refreshUI()
                        }
                    }
                }
            }
        }
    }
    
    private func getRecentMediaLibraryItems()  {
           manager.cancelPreviousRequest()
           self.mediaLibraryDataSource?.cellType = .recent
           mediaLibraryDataSource?.isLoading = true
           localProvider.fetchLocalMediaLibrary(mediaType: mediaSource, completion: { [weak self]mediaLibraryArray in
               self?.recentMediaArray = mediaLibraryArray
               if mediaLibraryArray.isEmpty {
                   self?.mediaLibraryDataSource?.cellType = .norecent
               }
               self?.mediaLibraryDataSource?.mediaLibraryArray.removeAll()
               self?.mediaLibraryDataSource?.mediaLibraryArray = mediaLibraryArray
               }, errorReceived: { error in
                   //No handling required
           })
           
       }
    
    @IBAction func backButtonAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

}
//MARK:- FTSegmentedControl Delegate
extension FTMediaLibraryViewController: FTSegmentedControlDelegate {
    func segmentedControlSelectedIndex(_ index: Int, animated: Bool, segmentedControl: FTSegmentedControl) {

        if lastSelectedCategoryState() == index {
            return
        }
        self.searchBar?.resignFirstResponder()
        page = 1
        manager.cancelPreviousRequest()
        mediaLibraryDataSource?.isLoading = true

        switch mediaSource {
        case .pixabay:
            UserDefaults.standard.setValue(index, forKey: PIXABAY_SEGMENTED_INDEX_KEY)
        case .unSplash:
            UserDefaults.standard.setValue(index, forKey: UNSPLASH_SEGMENTED_INDEX_KEY)
        }
        self.mediaLibraryDataSource?.mediaLibraryArray.removeAll()
        mediaLibraryDataSource?.refreshUI()
        fetchMediaLibraryBySelectedSource()
    }
    
    func didEndScrollOfSegments() {
        if mediaSource == .pixabay {
            track("pixabay_tab_scrolled", params: [:], screenName: FTScreenNames.noteBookAddNew)
        } else {
            track("unsplash_tab_scrolled", params: [:], screenName: FTScreenNames.noteBookAddNew)
        }
    }
    
    func didTapSegment(_ index: Int) {
        if mediaSource == .pixabay {
            track("pixabay_tab_tapped", params: [:], screenName: FTScreenNames.noteBookAddNew)
        } else {
            track("unsplash_tab_tapped", params: [:], screenName: FTScreenNames.noteBookAddNew)
        }
    }
}

// MARK: - Searchbar Delegate
extension FTMediaLibraryViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        mediaLibraryDataSource?.isLoading = true
        self.mediaLibraryDataSource?.cellType = .empty
        self.mediaLibraryDataSource?.mediaLibraryArray.removeAll()
        //For Recents Media are fetched from Search bar did end Editing
        self.searchText = searchBar.text ?? ""
        self.fetchMediaLibraryBySelectedSource()
        self.searchBar?.resignFirstResponder()
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if let text = searchBar.text, !text.isEmpty {
            track("stockimages_search_typed", params: ["searchTerm": text], screenName: FTScreenNames.noteBookAddNew)
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        debugLog("Cancel Button Tapped")
        self.searchBar?.resignFirstResponder()

        mediaLibraryDataSource?.isLoading = true
        self.mediaLibraryDataSource?.mediaLibraryArray.removeAll()
        mediaLibraryDataSource?.refreshUI()

        UIView.animate(withDuration: 0.3, animations: {
            self.searchBar?.isHidden = true
            self.searchBar?.frame.size.width = 0
            self.searchBar?.alpha = 0
            self.searchText = ""
          }, completion: { finished in
        })

        
        let lastState = lastSelectedCategoryState()
        let categorySegment =  categoriesContainerView?.subviews.last
        if  let categorySegment = categorySegment as? FTSegmentedControl {
                categorySegment.selectedIndex = lastState
            }
        
        fetchMediaLibraryBySelectedSource()
    }
}

// MARK: - FTMediaLibraryDataSourceDelegate
extension FTMediaLibraryViewController: FTMediaLibraryDataSourceDelegate {
    
    func fetchMediaForPage(forPage: Int) {
        self.page = forPage
        fetchMediaLibraryBySelectedSource()
    }
    
    func didSelectMediaImage(_ mediaLibraryImage: UIImage) {
        var source = FTInsertImageSourceClipart
        switch mediaSource {
        case .pixabay:
            source = FTInsertImageSourceClipart
        case .unSplash:
            source = FTInsertImageSourceUnSplash
        }
        var controllerToDismiss: UIViewController = self
        if let navVc = self.navigationController {
            controllerToDismiss = navVc
        }
        FTNotebookEventTracker.trackNotebookEvent(with: mediaSource.eventName)
        controllerToDismiss.dismiss(animated: true, completion: {
            self.delegate?.mediaLibraryViewController(self, didSelect: mediaLibraryImage, source: source)
        })

    }
    
    func dropSessionDidExit(dropSession session: UIDropSession) {
        if (self.navigationController?.view != nil) {
                 let point = session.location(in: self.navigationController!.view)
                    if (collectionView?.frame.contains(point))! {
                    } else {
                        for pageItem in session.items {
                            if let localObject = pageItem.localObject as AnyObject as? FTMediaLibraryModel {
                                   self.localProvider.addMediaLibraryModelToLocal(mediaLibraryModel: localObject)
                            }
                        }
                        var source = ""
                             switch mediaSource {
                             case .pixabay:
                                 source = "Clipart"
                             case .unSplash:
                                source = "UnSplash"

                             }
                        track("insert_image", params: ["source":source, "count": session.items.count])
                        self.navigationController?.dismiss(animated: true, completion: nil)
                    }
        }
        }
    
    func showAlert(title: String, message: String) {
        UIAlertController.showAlert(withTitle: title, message: "", from: self, withCompletionHandler: nil)
    }

}


extension FTMediaLibraryViewController {
    static func showAddMenuPixaBayController(from controller: UIViewController, mediaType: MediaSource, source: Any) {
        let storyboard = UIStoryboard.init(name: "FTDocumentEntity", bundle: nil)
        guard let mediaLibraryVc = storyboard.instantiateViewController(withIdentifier: "FTMediaLibraryViewController") as? FTMediaLibraryViewController else {
            fatalError("Programmer error, FTMediaLibraryViewController not found")
        }
        mediaLibraryVc.delegate = controller as? FTMediaLibrarySelectionDelegate
        mediaLibraryVc.mediaSource = mediaType
        mediaLibraryVc.shouldHideBackButton = true
        mediaLibraryVc.sourceType = .centerPanel
        mediaLibraryVc.ftPresentationDelegate.source = source as AnyObject
        controller.ftPresentPopover(vcToPresent: mediaLibraryVc, contentSize: AddMenuType.media.contentSize, hideNavBar: true)
    }
}
