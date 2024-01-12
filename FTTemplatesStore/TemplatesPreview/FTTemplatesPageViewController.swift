//
//  FTTemplatesPageViewController.swift
//  TempletesStore
//
//  Created by Siva on 07/03/23.
//

import UIKit
import Combine
import FTStyles
import FTCommon

protocol FTTemplatesPreviewDelegate: AnyObject {
    func didUpdateUIFor(favorate isFavorate: Bool)
    func showAndhideOptions(show: Bool)
    func didUpdateUIFor(sticker isDownloaded: Bool)
    func showAndhideSegment(show: Int)
}


class FTTemplatesPageViewController: UIViewController {

    private var cancellables = Set<AnyCancellable>()
    private var customTransitionDelegate = FTModalScaleTransitionDelegate()

    var templates: [TemplateInfo] = []
    var currentIndex: Int = 0
    private var scrollDirection : Int = 0
    private var _currentPageIndex: Int = 0
    private var previewControllers = [UIViewController]()
    private var orientation: ThumbnailOrientation = .potrait
    private var prevSize: CGSize = .zero

    @IBOutlet private weak var premiumIconView : UIImageView?

    @IBOutlet private weak var mainScrollView : UIScrollView?
    @IBOutlet private weak var topbar: UIView!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var previousButton: UIButton!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var orientationSegment: UISegmentedControl!
    @IBOutlet private weak var bottomActionsView: UIStackView!
    @IBOutlet private weak var downloadActionView: UIStackView!

    @IBOutlet private weak var favorateButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var createNotebookButton: UIButton!
    @IBOutlet private weak var downloadPackButton: UIButton!

    private var actionManager: FTStoreActionManager?
    private var cancellabelAction: AnyCancellable?;
    
    override func viewDidLoad() {
        super.viewDidLoad()
#if targetEnvironment(macCatalyst)
        self.mainScrollView?.contentInsetAdjustmentBehavior = .never;
#endif
        setupUI()
    }

    private func addObserver(_ template: TemplateInfo) {
        if nil == cancellabelAction
            , template.type == FTDiscoveryItemType.diary.rawValue
           , let premiumUser = FTStorePremiumPublisher.shared.premiumUser, !premiumUser.isPremiumUser {
            cancellabelAction = FTStorePremiumPublisher.shared.premiumUser?.$isPremiumUser.sink(receiveValue: { [weak self] isPremiumUser in
                self?.premiumIconView?.isHidden = isPremiumUser;
                if !(self?.isRegularClass() ?? false) {
                    self?.premiumIconView?.isHidden = true;
                }
            })
        }
    }
    
    private func removeObserver() {
        cancellabelAction?.cancel();
        cancellabelAction = nil;
    }
    deinit {
        removeObserver();
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.modalPresentationCapturesStatusBarAppearance = true
    }

    private var currentSize: CGSize = .zero;
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        createNotebookButton.layer.cornerRadius = 10
        updateScrollViewContentSizes()
        let frameSize = self.view.frame.size;
        if currentSize != frameSize {
            currentSize = frameSize;
            updateContentOffsetFor(page: self.currentIndex,animate: false);
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: {[weak self](_) in
            guard let self = self else { return }
            if let scrollView = self.mainScrollView {
                var contentOffset = scrollView.contentOffset
                contentOffset.x = CGFloat(self.currentIndex) * scrollView.frame.width
                scrollView.contentOffset = contentOffset
            }
        }, completion: { (_) in
        })
    }

    private func updateScrollViewContentSizes() {
        for (index, vc) in previewControllers.enumerated() {
            let rect = frameFor(index)
            vc.view.frame = rect;
        }
        if let mainScrollView {
            let maxWidth = CGFloat(previewControllers.count) * mainScrollView.frame.width
            mainScrollView.contentSize = CGSize(width: maxWidth, height: mainScrollView.frame.height)
        }
    }
    
    public static func presentFromViewController(_ viewController: UIViewController,
                                                 actionManager: FTStoreActionManager?,
                                                 templates: [TemplateInfo],
                                                 selectedIndex: Int) {
        if let vc = UIStoryboard.init(name: "FTTemplatesStore", bundle: storeBundle).instantiateViewController(withIdentifier: "FTTemplatesPageViewController") as? FTTemplatesPageViewController {
            vc.templates = templates
            vc.currentIndex = selectedIndex
            vc.actionManager = actionManager

#if targetEnvironment(macCatalyst)
            vc.modalPresentationStyle = .formSheet
            let insetBy: CGFloat = 20;
            var preferedSize = viewController.view.frame.insetBy(dx: insetBy, dy: 0).size;
            if let size = viewController.view.window?.windowScene?.sizeRestrictions?.minimumSize {
                preferedSize = CGSize(width: size.width - 2 * insetBy, height: size.height);
            }
            vc.preferredContentSize = preferedSize;
#else
            vc.modalPresentationStyle = .custom
            vc.transitioningDelegate = vc.customTransitionDelegate;
#endif
            viewController.present(vc, animated: true)
        }
    }

}

// MARK: - UI Methods
private extension FTTemplatesPageViewController {

    private func setupUI() {
        setupBlurEffectView()
        setupPageScrollView()
        bringSubViewsToFront()
    }

    func setupBlurEffectView() {
        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = self.view.bounds
        view.addSubview(blurView)
        view.sendSubviewToBack(blurView)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: self.view.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
    }

    private func bringSubViewsToFront() {
        view.bringSubviewToFront(closeButton)
        view.bringSubviewToFront(nextButton)
        view.bringSubviewToFront(previousButton)
        view.bringSubviewToFront(orientationSegment)

        createNotebookButton.configuration?.title = "templatesStore.templatePreview.createNotebook".localized
        view.bringSubviewToFront(createNotebookButton)
        view.bringSubviewToFront(downloadPackButton)
        view.bringSubviewToFront(favorateButton)

    }

}

// MARK: - ScrollView Configaration
private extension FTTemplatesPageViewController {
    private func templatesPreviewControllerForIndex(index: Int) -> UIViewController? {
        let vc = FTTemplatePreviewViewController.controller(template: templates[index], actionManager: actionManager, delegate: self, index: index)
        vc.modalPresentationStyle = .overCurrentContext
        return vc
    }

    private func stickersPreviewControllerForIndex(index: Int) -> UIViewController? {
        guard let vc = UIStoryboard.init(name: "FTTemplatesStore", bundle: storeBundle).instantiateViewController(withIdentifier: "FTStickersPreviewViewController") as? FTStickersPreviewViewController else {return nil}
        vc.template = templates[index]
        vc.currentIndex = index
        if index == 0 {
            vc.delegate = self
        }
        vc.modalPresentationStyle = .overCurrentContext
        return vc
    }

    private func setupPageScrollView() {
        self.mainScrollView?.frame = self.view.bounds

        for i in 0..<templates.count {
            let item = templates[currentIndex]
                if (item.type == FTDiscoveryItemType.template.rawValue || item.type == FTDiscoveryItemType.diary.rawValue || item.type == FTDiscoveryItemType.userJournals.rawValue), let vc = templatesPreviewControllerForIndex(index: i) as? FTTemplatePreviewViewController {
                    previewControllers.append(vc)
                    downloadActionView.isHidden = true
                } else if item.type == FTDiscoveryItemType.sticker.rawValue, let vc = stickersPreviewControllerForIndex(index: i) as? FTStickersPreviewViewController {
                    orientationSegment.isHidden = true
                    previewControllers.append(vc)
                    bottomActionsView.isHidden = true
                }
        }
        addAndRemovePreviewController()
        updateScrollViewContentSizes()
        updateContentOffsetFor(page: currentIndex,animate: false)
        let panGesture = UIPanGestureRecognizer.init(target: self, action: #selector(self.panGestureDetected(_:)))
        panGesture.delegate = self
        self.view.addGestureRecognizer(panGesture)
    }

    private func addPreviewVCAt(index: Int) {
        let vc = previewControllers[index]
        addChild(vc)
        if let mainScrollView {
            mainScrollView.addSubview(vc.view)
            let rect = frameFor(index)
            vc.view.frame = rect;
            if let controller = vc as? FTTemplatePreviewViewController {
                controller.addScrollViewSubViews()
            }
            vc.didMove(toParent: self)
        }
    }

    private func removePreviewAt(index: Int) {
        let controller = previewControllers[index]
        if let vc = controller as? FTTemplatePreviewViewController {
            vc.removeDelegate()
        }
        if let vc = controller as? FTStickersPreviewViewController {
            vc.delegate = nil
        }
        controller.willMove(toParent: nil)
        controller.view.removeFromSuperview()
        if let controller = controller as? FTTemplatePreviewViewController {
            controller.removeScrollViewSubViews()
        }
        controller.removeFromParent()
    }

    private func addAndRemovePreviewController() {
        var nextIndex = currentIndex + 1
        var previousIndex = currentIndex - 1
        previousIndex = max(previousIndex, 0)
        nextIndex = min(nextIndex, Int(templates.count-1))

        for i in 0..<templates.count {
            if i == currentIndex || i == previousIndex || i == nextIndex {
                addPreviewVCAt(index: i)
            } else if i != currentIndex || i != previousIndex || i != nextIndex {
                removePreviewAt(index: i)
            }
        }
    }

    private func frameFor(_ index: Int) -> CGRect {
        var rect = CGRect.zero
        rect.size.width = self.mainScrollView?.frame.width ?? 0
        rect.size.height = self.mainScrollView?.frame.height ?? 0
        rect.origin.x = (CGFloat)(index) * rect.width
        return rect
    }

    func updateContentOffsetFor(page: Int,animate: Bool = true) {
        var newPage = page
        newPage = max(newPage, 0)
        newPage = min(newPage, (templates.count-1))

        if let scrollView = mainScrollView {
            var contentOffset = scrollView.contentOffset
            contentOffset.x = CGFloat(newPage) * scrollView.frame.width
            currentIndex = newPage
            scrollView.setContentOffset(contentOffset, animated: animate)
            addAndRemovePreviewController()
        }

        /// Update Title
        let template = templates[currentIndex]
        titleLabel.text = template.title
        
        self.removeObserver();
        self.addObserver(template);
        
        self.premiumIconView?.isHidden = true;
        if template.type == FTDiscoveryItemType.diary.rawValue
            , let premiumUser = FTStorePremiumPublisher.shared.premiumUser
            , !premiumUser.isPremiumUser {
            self.premiumIconView?.isHidden = false;
            if !(self.isRegularClass() ) {
                self.premiumIconView?.isHidden = true;
            }
        }

        /// Enable and Disable
        previousButton.isEnabled = true
        nextButton.isEnabled = true

        if newPage == templates.count - 1 {
            nextButton.isEnabled = false
        }
        if newPage == 0 {
            previousButton.isEnabled = false
        }
        for(index, controller) in previewControllers.enumerated() {
            if let vc = controller as? FTTemplatePreviewViewController {
                if index == currentIndex {
                    vc.addDelegate(self)
                } else {
                    vc.removeDelegate()
                }
            } else if let vc = controller as? FTStickersPreviewViewController {
                if index == currentIndex {
                    vc.delegate = self
                } else {
                    vc.delegate = nil
                }
            }
        }
    }


}

// MARK: - PanGesture Observer
private extension FTTemplatesPageViewController {
    func canScrollTowards(_ direction: Int) -> Bool {
        let controller = self.previewControllers[currentIndex]
        if let vc = controller as? FTTemplatePreviewViewController {
            let offset = vc.canScrollTowards(direction)
            return !offset
        }
        return !false
    }

    @objc func panGestureDetected(_ panGesture: UIPanGestureRecognizer) {
        let trans = panGesture.translation(in: self.view)
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
        case .changed:
            if let scrollView = self.mainScrollView, canScrollTowards(scrollDirection) {
                var contentOffset = scrollView.contentOffset
                contentOffset.x -= trans.x
                contentOffset.x = max(contentOffset.x, -scrollView.frame.width*0.25)
                contentOffset.x = min(contentOffset.x, (scrollView.contentSize.width - scrollView.frame.width) + scrollView.frame.width*0.25)
                scrollView.contentOffset = contentOffset
                addAndRemovePreviewController()
            }
        case .ended:
            if canScrollTowards(scrollDirection), let scrollView = self.mainScrollView {
                let velocity = panGesture.velocity(in: self.view).x

                let contentOffset = scrollView.contentOffset
                var newPage = (CGFloat)(currentIndex)
                let newOffset = newPage * scrollView.frame.width
                if(
                    (velocity < -thresholdVelocity) ||
                    (contentOffset.x > (newOffset + scrollView.frame.width * 0.5))
                ) {
                    newPage += 1
                }
                else if((velocity > thresholdVelocity) ||
                        (contentOffset.x < (newOffset - scrollView.frame.width * 0.5))
                ){
                    newPage -= 1
                }
                updateContentOffsetFor(page: Int(newPage))
            }
            scrollDirection = 0
        default:
            break
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension FTTemplatesPageViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - IBActions
extension FTTemplatesPageViewController {
    @IBAction func closeAction(_ sender: Any) {
        self.mainScrollView?.removeFromSuperview()
        // Dismiss the view controller
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func orientationSwitchAction(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            orientation = .potrait
        } else {
            orientation = .landscape
        }
        previewControllers.forEach { controller in
            if let vc = controller as? FTTemplatePreviewViewController {
                vc.pageOrientationChange(orientation: orientation)
            }
        }
    }

    @IBAction func createNotebook(_ sender: Any) {
        if let vc = previewControllers[self.currentIndex] as? FTTemplatePreviewViewController {
            vc.createNoteBook()
        }
    }

    @IBAction func downloadStickersPack(_ sender: Any) {
        self.showingLoadingindicator()
        Task { @MainActor in
            if let vc = previewControllers[self.currentIndex] as? FTStickersPreviewViewController {
                do {
                    try await vc.downloadStickersPack()
                    didUpdateUIFor(sticker: true)
                    self.hideLoadingindicator()
                } catch {
                    UIAlertController.showAlert(withTitle: "templatesStore.alert.error".localized, message: error.localizedDescription, from: self, withCompletionHandler: nil)
                    didUpdateUIFor(sticker: false)
                    self.hideLoadingindicator()
                }
            }
        }
    }

    @IBAction func addToFavorite(_ sender: Any) {
        if let vc = previewControllers[self.currentIndex] as? FTTemplatePreviewViewController {
            vc.addToFavorite()
        }
    }

    @IBAction func previousAction(_ sender: Any) {
        var newPage = self.currentIndex
        newPage -= 1
        updateContentOffsetFor(page: newPage)
    }

    @IBAction func nextAction(_ sender: Any) {
        var newPage = self.currentIndex
        newPage += 1
        updateContentOffsetFor(page: newPage)
    }

}

// MARK: - FTTemplatesPreviewDelegate
extension FTTemplatesPageViewController: FTTemplatesPreviewDelegate {
    func showAndhideSegment(show: Int) {
        if show == 0 {
            self.orientationSegment.isHidden = false
        } else {
            self.orientationSegment.isHidden = true
        }
    }

    func showAndhideOptions(show: Bool) {
        if show {
            if self.bottomActionsView.alpha == 0 {
                bottomActionsView.isHidden = false
                UIView.animate(withDuration: 0.5, animations: {
                    self.bottomActionsView.alpha = 1
                })
            }
        } else {
            bottomActionsView.alpha = 0
            bottomActionsView.isHidden = true
        }
    }

    func didUpdateUIFor(favorate isFavorate: Bool) {
        let tickIcon = UIImage(systemName: "checkmark")?.withConfiguration(UIImage.SymbolConfiguration(font: UIFont.appFont(for: .semibold, with: 13))).withTintColor(.white)
        let attachment = NSTextAttachment()
        attachment.image = tickIcon

        let attachmentBounds = CGRect(x: 0, y: 3, width: attachment.image!.size.width, height: attachment.image!.size.height)
        attachment.bounds = attachmentBounds

        var title = "templatesStore.templatePreview.inyourLibrary".localized
        var textColor = UIColor.white

        if isFavorate {
            title = "templatesStore.templatePreview.inyourLibrary".localized
            favorateButton.backgroundColor = UIColor(hexString: "E7B647")
            favorateButton.layer.borderColor = UIColor.clear.cgColor
            favorateButton.layer.cornerRadius = 10
        } else {
            title = "templatesStore.templatePreview.addtoLibrary".localized
            textColor = UIColor.appColor(.accent)
            favorateButton.layer.borderColor = UIColor.appColor(.accent).cgColor
            favorateButton.backgroundColor = .clear
            favorateButton.layer.cornerRadius = 10
            favorateButton.layer.borderWidth = 1
        }
        let attachmentString = NSAttributedString(attachment: attachment)
        let titleAttributedString = NSMutableAttributedString(string: title + " " ,attributes: [.font: UIFont.clearFaceFont(for: .medium, with: 20), .foregroundColor :textColor])
        if isFavorate {
            titleAttributedString.append(attachmentString)
        }
        self.favorateButton.setAttributedTitle(titleAttributedString, for: .normal)

    }

    func didUpdateUIFor(sticker isDownloaded: Bool) {
        let tickIcon = UIImage(systemName: "checkmark")?.withConfiguration(UIImage.SymbolConfiguration(font: UIFont.appFont(for: .semibold, with: 13))).withTintColor(.white)
        let attachment = NSTextAttachment()
        attachment.image = tickIcon

        let attachmentBounds = CGRect(x: 0, y: 3, width: attachment.image!.size.width, height: attachment.image!.size.height)
        attachment.bounds = attachmentBounds

        var title = "templatesStore.stickerPreview.downloaded".localized

        if isDownloaded {
            title = "templatesStore.stickerPreview.downloaded".localized
            downloadPackButton.backgroundColor = UIColor(hexString: "E7B647")
            downloadPackButton.layer.cornerRadius = 10
        } else {
            title = "templatesStore.stickerPreview.downloadPack".localized
            downloadPackButton.backgroundColor = UIColor.appColor(.accent)
            downloadPackButton.layer.cornerRadius = 10
        }
        let attachmentString = NSAttributedString(attachment: attachment)
        let titleAttributedString = NSMutableAttributedString(string: title + " " ,attributes: [.font: UIFont.clearFaceFont(for: .medium, with: 20), .foregroundColor : UIColor.white])
        if isDownloaded {
            titleAttributedString.append(attachmentString)
        }
        downloadPackButton.setAttributedTitle(titleAttributedString, for: .normal)
    }

}

#if targetEnvironment(macCatalyst)
extension FTTemplatesPageViewController: FTKeyCommandAction {
    @objc func moveToNextPreview(_ sender:Any) {
        if let controller = self.previewControllers[currentIndex] as? FTTemplatePreviewViewController {
            if controller.canScrollTowards(1) {
                controller.moveToPage(index: controller.currentPage+1)
            }
            else {
                self.nextAction(sender);
            }
        }
    }
    
    @objc func moveToPreviousPreview(_ sender:Any) {
        if let controller = self.previewControllers[currentIndex] as? FTTemplatePreviewViewController {
            if controller.canScrollTowards(2) {
                controller.moveToPage(index: controller.currentPage-1)
            }
            else {
                self.previousAction(sender);
            }
        }
    }
    
    override var keyCommands: [UIKeyCommand]? {
        return [
            FTKeyCommand.nextPage()
            ,FTKeyCommand.nextPage(.command)
            ,FTKeyCommand.previousPage()
            ,FTKeyCommand.previousPage(.command)
            ,FTKeyCommand.closeModalWindow
        ];
    }
    
    func didTapOnClose(_ sender: UIKeyCommand) {
        self.closeAction(sender);
    }
    
    func didTapMoveNextPage(_ sender: UIKeyCommand) {
        if sender.modifierFlags == .command {
            self.nextAction(sender)
        }
        else {
            self.moveToNextPreview(sender);
        }
    }
    
    func didTapMovePreviousPage(_ sender: UIKeyCommand) {
        if sender.modifierFlags == .command {
            self.previousAction(sender);
        }
        else {
            self.moveToPreviousPreview(sender);
        }
    }
}
#endif
