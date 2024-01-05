//
//  FTTemplatePreviewViewController.swift
//  TempletesStore
//
//  Created by Siva on 24/02/23.
//

import UIKit
import Combine
import FTCommon
import AVFoundation
import Network

let thresholdVelocity: CGFloat = 1000

enum ThumbnailOrientation: Int, Codable {
    case all = 0, potrait = 1, landscape = 2
}

struct FTTemplatePreviewDetails {
    var template: TemplateInfo
    var style: FTTemplateStyle
    var orientation: ThumbnailOrientation
    init(template: TemplateInfo, style: FTTemplateStyle, orientation: ThumbnailOrientation) {
        self.template = template
        self.style = style
        self.orientation = orientation
    }
}

class FTTemplatePreviewViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet private weak var scrollViewContainer: UIView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var topScrollView: UIScrollView!
    @IBOutlet private weak var pagecontrol: UIPageControl!
    @IBOutlet private weak var collectionContainerViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var collectionContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var scrollViewContainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var scrollViewContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var styleName: UILabel!
    @IBOutlet weak var collectionContainerView: UIView!

    @IBOutlet weak var userJournalStackView: UIStackView!
    @IBOutlet weak var styleStackView: UIStackView!
    @IBOutlet weak var userJournalDescription: UILabel!
    @IBOutlet weak var authorImageView: UIImageView!
    @IBOutlet weak var authorButton: UIButton!

    // MARK: - Private variables
    private var thumbnailOrientation: ThumbnailOrientation = .potrait
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var viewModel = FTTemplatePreviewViewModel()
    private var pageActionManager = FTTemplatesPageActionManager.shared
    private var previewImageViews = [UIImageView]()
    private var viewWidth = 100.0
    private var viewHeight = 140.0
    private var _currentPageIndex: Int = 0
    private var scrollDirection: Int = 0
    private var prevSize: CGSize = .zero

    private var indicatorView: UIView!

    var networkCheck = FTNetwork.sharedInstance()

    var template: TemplateInfo!
    var currentIndex: Int = 0

    weak var delegate: FTTemplatesPreviewDelegate? {
        didSet {
            updateFavorateStatus()
        }
    }

    var currentPage = 0 {
        didSet {
            updateFavorateStatus()
        }
    }

    var styles: [FTTemplateStyle]? {
        if var styles = self.template.styles {
            styles = styles.map { style in
                var updatedStyle = style
                updatedStyle.orientation = thumbnailOrientation // Update the value here
                return updatedStyle
            }
            if previewImageViews.count > 0, let supportOrientation = template.supportOrientation {
                if thumbnailOrientation != ThumbnailOrientation(rawValue: supportOrientation) {
                    self.pageOrientationChange(orientation: ThumbnailOrientation(rawValue: supportOrientation) ?? .potrait)
                }
                self.delegate?.showAndhideSegment(show: supportOrientation)
            } else {
                self.delegate?.showAndhideSegment(show: 0)
            }

            return styles
        }
        return []
    }

    // MARK: - View hierarchy Begans
    override func viewDidLoad() {
        super.viewDidLoad()

        // This code is to show Author information and Planner description for User journals
        if self.template.sectionType == FTStoreSectionType.userJournals.rawValue {        userJournalDescription.text = self.template.subTitle
            styleStackView.isHidden = true
            userJournalStackView.isHidden = false
            authorImageView.isHidden = false
            authorImageView.layer.cornerRadius = 36
            loadAuthorDetails()
        } else {
            styleStackView.isHidden = false
            userJournalStackView.isHidden = true
            authorImageView.isHidden = true
        }
        networkCheck.addObserver(observer: self)
        setupUI()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pageActionManager.cancellables.removeAll()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: {[weak self](_) in
            guard let self = self else { return }
            self.updateScrollViewContentSizes()
        }, completion: { (_) in
        })
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if(prevSize != self.view.frame.size) {
            prevSize = self.view.frame.size;
            updateScrollViewContentSizes()
        }
    }

    func loadAuthorDetails() {
        if let authorImageUrl = self.template.authorImageUrl {
            authorImageView.sd_setImage(with: authorImageUrl, placeholderImage: nil, options: .refreshCached)
        }
        authorButton.setTitle(template.author, for: .normal)
    }

    @IBAction func authorAction(_ sender: Any) {
        if let openUrl = template.link, let url = URL(string: openUrl) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
}

extension FTTemplatePreviewViewController {

    func updateScrollViewContentSizes() {
        let userJournalHeight = userJournalStackView.frame.height + 40
        let availableWidth = self.view.frame.width - 88
        var availableHeight =  min(self.view.frame.height - 354 - userJournalHeight, 750)
        if !self.isRegularClass() {
            availableHeight -= 150
        }
        var aspectSize = FTStoreConstants.TemplatePreview.potraitAspectSize
        if self.thumbnailOrientation == .landscape {
            aspectSize = FTStoreConstants.TemplatePreview.landscapeAspectSize
        }

        if self.template.type == FTDiscoveryItemType.diary.rawValue {
            aspectSize = FTStoreConstants.DiaryPreview.potraitAspectSize
            if self.thumbnailOrientation == .landscape {
                aspectSize = FTStoreConstants.DiaryPreview.landscapeAspectSize
            }
        }

        let aspectRect = AVMakeRect(aspectRatio: aspectSize , insideRect: CGRect(x: 0, y: 0, width: availableWidth, height: availableHeight))
        if aspectRect.width != self.scrollViewContainerWidthConstraint.constant {
            scrollViewContainerWidthConstraint.constant = aspectRect.width
            scrollViewContainerViewHeightConstraint.constant = aspectRect.height
            scrollView.frame.size = aspectRect.size
            topScrollView.setNeedsLayout()
            topScrollView.layoutIfNeeded()
        }
        for (index, imageView) in previewImageViews.enumerated() {
            imageView.transform = .identity
            imageView.frame = self.frameFor(index)
            previewImageViews[index] = imageView
        }
        let maxWidth = CGFloat(previewImageViews.count) * scrollView.frame.width
        scrollView.contentSize = CGSize(width: maxWidth, height:scrollView.frame.size.height)
        topScrollView.contentSize = CGSize(width: CGFloat(previewImageViews.count) * topScrollView.frame.width, height:topScrollView.frame.size.height)
        viewModel.thumbnailSize = aspectSize
        if let styles {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let collectionVidth = CGFloat(self.collectionView.contentSize.width) + CGFloat((styles.count - 1) * 6)
                self.collectionContainerViewWidthConstraint.constant = min(collectionVidth, self.view.frame.size.width - 88)
                self.collectionContainerViewHeightConstraint.constant = 46
                if self.template.type == FTDiscoveryItemType.diary.rawValue || self.template.sectionType == FTStoreSectionType.userJournals.rawValue {
                    if self.thumbnailOrientation == .potrait {
                        self.collectionContainerViewHeightConstraint.constant = 72
                    }
                }
            }
        }

        updateContentOffset()
        topScrollView.updateConstraintsIfNeeded()
        topScrollView.layoutIfNeeded()
    }

    func updateFavorateStatus() {
        if var style = self.currentStyle() {
            if template.type == FTDiscoveryItemType.diary.rawValue {
                style.templateName = template.fileName
            }
            let isFavorate = FTStoreLibraryHandler.shared.isInStoreLibrary(template: style)
            self.delegate?.didUpdateUIFor(favorate: isFavorate)
        }
    }

    func removeScrollViewSubViews() {
        previewImageViews.forEach { imageView in
            imageView.image = nil
            imageView.removeFromSuperview()
        }
    }

    func addScrollViewSubViews() {
        for (index, imageView) in previewImageViews.enumerated() {
            let view = scrollView.subviews.filter {$0 == imageView}
            if view.count == 0 {
                updatePreviewAt(index: index)
                scrollView.addSubview(imageView)
            }
        }
    }

}

// MARK: - Custom Methods
private extension FTTemplatePreviewViewController {

    func setupUI() {
        viewModel.template = template
        initializeActivityIndicator()
        downloadThumbnailPdfIfNeeded()
        scrollViewConfig()
        collectionView.reloadData()
        updatePreviewAt(index: 0)
        pagecontrol.currentPage = 0
        updatePageIndicationAt(index: 0)

        /// Change Template orientation based on supporting Orientation
        if let supportOrientation = self.template.supportOrientation {
            thumbnailOrientation = ThumbnailOrientation.init(rawValue: supportOrientation) ?? .all
            self.pageOrientationChange(orientation: ThumbnailOrientation.init(rawValue: supportOrientation) ?? .all)
            self.delegate?.showAndhideSegment(show: supportOrientation)
        }
    }

    func scrollViewConfig() {
        viewWidth = scrollViewContainer.frame.width
        viewHeight = scrollViewContainer.frame.height

        scrollViewContainer.layer.cornerRadius = 10
        self.scrollViewContainer.backgroundColor = .gray.withAlphaComponent(0.1)
        scrollViewContainer.addShadow(cornerRadius: 10, color: UIColor.appColor(.black10), offset: CGSize(width: 0, height: 10), opacity: 1, shadowRadius: 30)

        self.topScrollView.bounds = view.bounds
        self.topScrollView.decelerationRate = .fast
        self.topScrollView.isScrollEnabled = false
        self.scrollView.isScrollEnabled = false

        scrollView.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
        scrollView.center.x = view.bounds.midX
        scrollView.center.y = view.bounds.midY
        self.scrollView.layer.cornerRadius = 10
        var x : CGFloat = 0

        if let styles {
            for (index, _) in styles.enumerated() {
                let previewImageView = FTTemplateImageView(frame: CGRect(x: x , y: 0, width: viewWidth , height: viewHeight))
                previewImageView.layer.cornerRadius = 10
                previewImageView.clipsToBounds = true
                previewImageViews.append(previewImageView)
                scrollView.addSubview(previewImageView)
                previewImageView.configureImageViewWith(template: self.template)
                updatePreviewAt(index: index)
                x += viewWidth
            }
            scrollView.contentSize = CGSize(width: x, height:scrollView.frame.size.height)
            topScrollView.contentSize = CGSize(width: view.frame.width * CGFloat(styles.count), height:topScrollView.frame.size.height)

            pagecontrol.numberOfPages = styles.count

            updateScrollViewContentSizes()

            let panGesture = UIPanGestureRecognizer.init(target: self, action: #selector(self.panGestureDetected(_:)))
            panGesture.delegate = self
            self.view.addGestureRecognizer(panGesture)
        }

    }

    @IBAction func pageControlAction(_ sender: UIPageControl) {
        let pageIndex = sender.currentPage
        currentPage = pageIndex
        updateContentOffset()
        updatePageIndicationAt(index: sender.currentPage)
    }

    func frameFor(_ index: Int) -> CGRect {
        var rect = CGRect.zero
        rect.size.width = self.scrollView.frame.width
        rect.size.height = self.scrollView.frame.height
        rect.origin.x = (CGFloat)(index) * rect.width
        return rect
    }

    func updateContentOffset() {
        for (index, imageView) in previewImageViews.enumerated() {
            imageView.transform = .identity
            imageView.frame = self.frameFor(index)
            previewImageViews[index] = imageView
        }

        self.topScrollView.contentOffset = CGPoint(x: CGFloat(self.currentPage) * self.topScrollView.frame.width, y: self.topScrollView.contentOffset.y)
        self.scrollView.contentOffset = CGPoint(x: CGFloat(self.currentPage) * self.scrollView.frame.width, y: self.scrollView.contentOffset.y)
        updateFavorateStatus()
    }

    func initializeActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        indicatorView = UIView(frame: self.view.bounds)
        indicatorView.backgroundColor = .clear
        indicatorView.addSubview(activityIndicator)
        if let parent = self.parent as? FTTemplatesPageViewController {
            parent.view.addSubview(indicatorView)
            parent.view.bringSubviewToFront(indicatorView)
        }
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: indicatorView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: indicatorView.centerYAnchor),
        ])
    }

    func updatePreviewAt(index: Int) {
        guard let styles else { return }
        let style = styles[index]
        let imageView = previewImageViews[index]

        let fileUrl = style.thumbnailPath()
        if let image = UIImage(contentsOfFile: fileUrl.path) {
            imageView.image = image
        } else {
            print("Error setting image to UIImageView", fileUrl.lastPathComponent)
        }
    }

    func updatePageIndicationAt(index: Int) {
        let selectedIndexPath = IndexPath(item: index, section: 0)
        self.collectionView.selectItem(at: selectedIndexPath, animated: true, scrollPosition: .centeredHorizontally)
        self.pagecontrol.currentPage = index
        if let style = styles?[self.currentPage] {
            self.styleName.text = style.title
        }
    }

    func currentStyle() -> FTTemplateStyle? {
        guard let styles, styles.count - 1 >= currentPage else {
            return nil
        }
        var style = styles[currentPage]
        style.orientation = thumbnailOrientation
        return style
    }

    func downloadThumbnailPdfIfNeeded()  {
        guard let styles else { return }
        Task {
            await withThrowingTaskGroup(of: Void.self) { group in
                for (_, style) in styles.enumerated() {
                    group.addTask {
                        await self.startActivityIndicator()
                        do {
                            var thumbUrl = style.thumbnailPath()
                            thumbUrl = try await self.viewModel.downloadTemplateFor(style: style)
                            var name = thumbUrl.lastPathComponent.deletingPathExtension
                            if await self.thumbnailOrientation == .potrait {
                                name = name.replacingOccurrences(of: "_port", with: "")
                            } else {
                                name = name.replacingOccurrences(of: "_land", with: "")
                            }
                            if let index = styles.firstIndex(where: {$0.templateName == name}) {
                                await self.updateUIAt(index: index)
                            }
                            await self.stopActivityIndicator()
                        } catch {
                            await self.stopActivityIndicator()
                        }
                    }
                }
            }
        }
    }
    
    @MainActor
    func updateUIAt(index: Int) async {
         self.updatePreviewAt(index: index)
         self.updateScrollViewContentSizes()
         self.updatePageIndicationAt(index: self.currentPage)
    }

}

// MARK: - Pangesturs Observer

extension FTTemplatePreviewViewController {
    func canScrollTowards(_ direction: Int) -> Bool {
        let numberOfPages = styles?.count ?? 0
        if(direction == 1) {
            if(currentPage == numberOfPages - 1) {
                return false
            }
        }
        else if(direction == 2) {
            if currentPage == 0 {
                return false
            }
        }
        return true
    }

    @objc func panGestureDetected(_ panGesture: UIPanGestureRecognizer) {
        let numberOfPages = styles?.count ?? 0
        let trans = panGesture.translation(in: self.view)
        self.scrollViewContainer.backgroundColor = .gray.withAlphaComponent(0.1)
        if(scrollDirection == 0) {
            if(trans.x < 0) {
                scrollDirection = 1
            }
            else if(trans.x > 0) {
                scrollDirection = 2
            }
        }
        if(scrollDirection != 0) {
            panGesture.setTranslation(.zero, in: self.view)
        }
        switch panGesture.state {
        case .began:
            scrollDirection = 0
            let contentOffset = self.topScrollView.contentOffset
            let currentPageIndex = (Int)(contentOffset.x / self.topScrollView.frame.width)
            _currentPageIndex = currentPageIndex
        case .changed:
            if(canScrollTowards(scrollDirection)) {
                var contentOffset = self.topScrollView.contentOffset
                contentOffset.x -= trans.x
                self.topScrollView.contentOffset = contentOffset
            }
        case .ended:
            if(canScrollTowards(scrollDirection)) {
                let velocity = panGesture.velocity(in: self.view).x
                var contentOffset = self.topScrollView.contentOffset
                var newPage = (CGFloat)(_currentPageIndex)
                let newOffset = newPage * self.topScrollView.frame.width
                if (
                    (velocity < -thresholdVelocity)
                    || (contentOffset.x > (newOffset + self.topScrollView.frame.width * 0.5))
                ) {
                    newPage += 1
                }
                else if(
                    (velocity > thresholdVelocity)
                    || (contentOffset.x < (newOffset - self.topScrollView.frame.width * 0.5))
                ) {
                    newPage -= 1
                }
                newPage = max(newPage, 0)
                newPage = min(newPage, (CGFloat)(numberOfPages-1))
                contentOffset.x = newPage * self.topScrollView.frame.width
                self.currentPage = Int(newPage)

                // Load Preview for comming page
                if let styles, styles.count != self.currentPage {
                    updatePreviewAt(index: self.currentPage)
                }
                self.updatePageIndicationAt(index: self.currentPage)
                self.topScrollView.setContentOffset(contentOffset, animated: true)
  }
            scrollDirection = 0
        default:
            break
            }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let point = touch.location(in: collectionView)
        if collectionView.frame.contains(point) {
            return false
        }
        return true
    }

}
// MARK: - UIGestureRecognizerDelegate
extension FTTemplatePreviewViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - Observers
 extension FTTemplatePreviewViewController {

    func addToFavorite() {
        if var style = self.currentStyle() {
            if !FileManager.default.fileExists(atPath: style.pdfPath().path) && networkCheck.currentStatus == .unsatisfied {
                showNetworkAlert()
                return
            }
            if template.type == FTDiscoveryItemType.diary.rawValue {
                style = styles?.first ?? style
                style.stylePath = style.templateName
                style.templateName = template.fileName
                style.previewToken = template.previewToken
            }

            let isFavorate = FTStoreLibraryHandler.shared.isInStoreLibrary(template: style)
            style.orientation = thumbnailOrientation
            if isFavorate {
                Task {
                    try await FTStoreLibraryHandler.shared.removeFromLibrary(template: style)
                    updateFavorateStatus()
                }
            } else {
                Task {
                    try await FTStoreLibraryHandler.shared.saveIntoLibrary(style: style, title: template.title)
                    updateFavorateStatus()
                }
                // Track Event
                FTStoreContainerHandler.shared.actionStream.send(.track(event: EventName.template_preview_addtolibrary_tap, params: [EventParameterKey.title: style.templateName], screenName: ScreenName.templatesStore))

            }
        }
    }

    func pageOrientationChange(orientation: ThumbnailOrientation) {
        thumbnailOrientation = orientation
        let imageView = previewImageViews[self.currentPage]
        imageView.image = nil
        updateScrollViewContentSizes()
        downloadThumbnailPdfIfNeeded()
        self.collectionView.reloadData()
    }

     func createNoteBook() {
        if template.type == FTDiscoveryItemType.diary.rawValue {
            if let premiumUser = FTStoreContainerHandler.shared.premiumUser, premiumUser.isPremiumUser {
                presentDatePicker()
            }
            else {
                FTStoreContainerHandler.shared.actionStream.send(.showUpgradeAlert(controller: self, feature: "Digital Diary"));
            }
        } else {
            if FTStoreContainerHandler.shared.premiumUser?.nonPremiumQuotaReached ?? false {      FTStoreContainerHandler.shared.actionStream.send(.showUpgradeAlert(controller: self, feature: nil));
                return;
            }
            if template.sectionType == FTStoreSectionType.userJournals.rawValue {
                Task {
                    try await createNotebookForInspirationJournal()
                }
            } else {
                if let style = self.currentStyle() {
                    let fileUrl = style.pdfPath()
                    if !FileManager.default.fileExists(atPath: fileUrl.path) && networkCheck.currentStatus == .unsatisfied {
                        showNetworkAlert()
                        return
                    }
                    createNotebookFor(fileUrl: fileUrl, fileName: template.title)
                    // Track Event
                    FTStoreContainerHandler.shared.actionStream.send(.track(event: EventName.template_preview_createnotebook_tap, params: [EventParameterKey.title: style.templateName], screenName: ScreenName.templatesStore))
                }
            }
        }
    }

     func createNotebookForInspirationJournal() async throws {
         let storeServiceApi = FTStoreService()
         guard let templa = template as? DiscoveryItem else {
             throw TemplateDownloadError.InvalidTemplate
         }
         guard let downloadUrl = templa.inspirationsUrl else {
             throw TemplateDownloadError.InvalidTemplate
         }
         self.showingLoadingindicator()
         let fileUrl = try await storeServiceApi.downloadinspirationJournalFor(url: downloadUrl, fileName: templa.fileName)
         self.hideLoadingindicator()
         createNotebookFor(fileUrl: fileUrl.appendingPathComponent(templa.fileName).appendingPathExtension("pdf"), fileName: templa.title)
     }

     func createNotebookFor(fileUrl: URL, fileName: String) {
         let name = "\(fileName)"
         let tempUrl = FTTemplatesCache().temporaryFolder.appendingPathComponent(name).appendingPathExtension(fileUrl.pathExtension)
         Task {
             do {
                 if FileManager.default.fileExists(atPath: tempUrl.path) {
                     try FileManager.default.removeItem(at: tempUrl)
                 }
                 try FileManager.default.copyItem(at: fileUrl, to: tempUrl)
                 let isDark = false
                 let isLandscape = self.template.supportOrientation == 2 ? true : false
                 FTStoreContainerHandler.shared.actionStream.send(.createNotebookForTemplate(url: tempUrl, isLandscape: isLandscape, isDark: isDark))
             } catch let error {
                 UIAlertController.showAlert(withTitle: "templatesStore.alert.error".localized, message: error.localizedDescription, from: self, withCompletionHandler: nil)
             }
         }
     }

     func presentDatePicker() {
         FTDairyDateSelectionPicker_iOS.presentDatePicker(template: template, delegate: self, onViewController: self);
     }

    @MainActor
    func startActivityIndicator() {
        indicatorView.isHidden = false
        activityIndicator.startAnimating()
    }

    @MainActor
    func stopActivityIndicator() {
        activityIndicator.stopAnimating()
        indicatorView.isHidden = true
    }
     
     func moveToPage(index: Int) {
         currentPage = index
         if let styles, styles.count != self.currentPage {
             updatePreviewAt(index: self.currentPage)
         }
         self.updatePageIndicationAt(index: self.currentPage)
         updateContentOffset()
     }

     private func showNetworkAlert() {
         UIAlertController.showAlert(withTitle: "MakeSureYouAreConnected".localized, message: "", from: self, withCompletionHandler: nil)
     }

}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension FTTemplatePreviewViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return styles?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FTTemplateStyleCell.reuseIdentifier, for: indexPath) as? FTTemplateStyleCell else { return UICollectionViewCell() }
        if let style = styles?[indexPath.item] {
            cell.prepareCellWith(style: style, template: template)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.moveToPage(index: indexPath.row);
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let style = styles?[indexPath.item] {
            if style.type == FTDiscoveryItemType.diary.rawValue || style.type == FTDiscoveryItemType.userJournals.rawValue  {
                if thumbnailOrientation == .potrait {
                    return  CGSize(width: 52, height: 71)
                } else {
                    return  CGSize(width: 70, height: 47)
                }
            }
        }
        return  CGSize(width: 44, height: 44)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16.0
    }
    
}

extension FTTemplatePreviewViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scale = self.scrollView.frame.width / topScrollView.frame.width
        self.scrollView.contentOffset.x = (topScrollView.contentOffset.x) * scale
        let offsetX = self.scrollView.contentOffset.x
        let screenWidth = view.frame.width
        for (index, subview) in previewImageViews.enumerated() {
            let subviewX = subview.frame.origin.x
            let delta = subviewX - offsetX
            let ratio = delta / screenWidth
            let transform = CGAffineTransform(translationX: 0, y: 0)
            subview.transform = transform.scaledBy(x: 1 - abs(ratio) * 0.5, y: 1 - abs(ratio) * 0.5)
            previewImageViews[index] = subview
        }
    }
}

extension FTTemplatePreviewViewController: FTDairyDateSelectionPickerDelegate {
    func onDatesSelected(_ generatorController: FTDairyDateSelectionPickerController, startDate: Date, endDate: Date) {
        if self.currentStyle() != nil {
            var isLandscape = false
            if thumbnailOrientation == .landscape {
                isLandscape = true
            }
            if let thumbnailUrl = template.thumbnailUrl {
                UIImageView().sd_setImage(with: thumbnailUrl
                                          , placeholderImage: nil
                                          , options: .refreshCached) { [weak self] image, _, _, _ in
                    guard let self = self else { return }
                    if let image {
                        FTStoreContainerHandler.shared.actionStream.send(.createNotebookForDairy(fileName: self.template.fileName, title: self.template.title, startDate: startDate, endDate: endDate, coverImage: image, isLandScape: isLandscape))
                    }
                }
            }
        }
    }
}

// MARK: - Network Observer
extension FTTemplatePreviewViewController: FTNetworkObserver {
    func networkStatusDidChange(status: NWPath.Status) {
        if status == .satisfied {
            downloadThumbnailPdfIfNeeded()
            self.collectionView.reloadData()
        }
    }
}
