//
//  FTToolbarCenterPanelController.swift
//  Noteshelf3
//
//  Created by Narayana on 20/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon
import TipKit

protocol FTToolbarCenterPanelDelegate: AnyObject {
    func isZoomModeEnabled() -> Bool
    func currentDeskMode() -> RKDeskMode?
    func maxCenterPanelItemsToShow() -> Int
    func didTapCenterPanelButton(type: FTDeskCenterPanelTool, sender: UIView)
}

@available (iOS 17.0, *)
struct NewFeatures: Tip{
    var title : Text {
        Text("tipeview.shortcut.title".localized)
            .foregroundStyle(.white)
            
    }
    var message: Text?{
        Text("tipeview.shortcut.message".localized)
            .foregroundStyle(Color(uiColor: UIColor.white.withAlphaComponent(0.7) ))
    }
    
    var image : Image? {
        Image(uiImage: UIImage(named: "desk_tool_bulb") ?? UIImage())
    }
    
}
@available (iOS 17.0, *)
struct CustomTiPView : TipViewStyle {
  @State var size: CGSize = .zero
  func makeBody(configuration: Configuration) -> some View {
    HStack(alignment: .top, spacing: 12) {
      VStack {
        configuration.image?
          .resizable()
          .frame(width: 32, height: 32)
          .aspectRatio(contentMode: .fit)
          .padding(.top,2)
        Spacer()
          .frame(maxHeight: self.size.height)
      }
      VStack(alignment: .leading) {
        configuration.title
              .font(.system(size:17,weight: .bold))
          .fixedSize(horizontal: false, vertical: true)
        configuration.message?
          .font(.subheadline)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(
      GeometryReader { geometry in
        Color.clear
          .onAppear {
            self.size = geometry.size
          }
      })
  }
}
    
class FTToolbarCenterPanelController: UIViewController {
    private weak var customToolbarObserver: NSObjectProtocol?;

    @IBOutlet private weak var containerView: FTToolbarVisualEffectView?
    @IBOutlet private weak var collectionView: FTCenterPanelCollectionView!
    @IBOutlet private weak var leftNavBtn: UIButton?
    @IBOutlet private weak var rightNavBtn: UIButton?
    @IBOutlet private weak var leftSpacer: UIView?
    @IBOutlet private weak var rightSpacer: UIView?

    @IBOutlet private weak var navBtnWidthConstraint: NSLayoutConstraint?
    @IBOutlet private weak var collectionViewWidthConstraint: NSLayoutConstraint?

    private var dataSourceItems: [FTDeskCenterPanelTool] = []
    private(set) var screenMode = FTScreenMode.normal
    private var showTipView :  Bool = false

    weak var delegate: FTToolbarCenterPanelDelegate?

    private var deskToolWidth: CGFloat {
        return self.collectionView?.deskToolWidth ?? 40
    }

    private var navButtonWidth: CGFloat {
        var reqWidth = FTToolbarConfig.CenterPanel.NavButtonWidth.regular
        if self.screenMode == .shortCompact {
            reqWidth = FTToolbarConfig.CenterPanel.NavButtonWidth.compact
        }
        return reqWidth
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.centerPanelDelegate = self
        self.addObservers()
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.6
        self.view.addGestureRecognizer(longPressGesture)
        addObserverForScrollDirection()
        
    }
    override func viewDidAppear(_ animated: Bool) {
        self.showTipView = UserDefaults.standard.bool(forKey: "showTipView")
        if FTUtils.isAppInstalledFor(days: 5) {
            if self.showTipView == false {
                if self.view.frame.width > 320 {
                    setUpTipForNewFeatures()
                }
                UserDefaults.standard.set(true, forKey: "showTipView")
            }
        }
       
    }

    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            FTCustomizeToolbarController.showCustomizeToolbarScreen(controller: self)
            // Track Event
            track(EventName.toolbar_longpress)
        }
    }

    deinit {
        if let observer = self.customToolbarObserver {
            NotificationCenter.default.removeObserver(observer);
        }
        NotificationCenter.default.removeObserver(self)
    }

    func centerPanelVisualEffectBlurView() -> FTToolbarVisualEffectView? {
        return self.containerView
    }

    func updateActionDelegate(_ del: FTToolbarCenterPanelDelegate) {
        self.delegate = del
    }

    func updateScreenMode(_ mode: FTScreenMode) {
        self.screenMode = mode
        self.updateCenterPanel()
    }

     func updateCenterPanel() {
        self.dataSourceItems = FTCurrentToolbarSection().displayTools
        guard let maxToShow = self.delegate?.maxCenterPanelItemsToShow() else {
            return
        }
        self.view.alpha = self.dataSourceItems.isEmpty ? 0.0 : 1.0
        self.navBtnWidthConstraint?.constant = navButtonWidth
        if self.screenMode == .shortCompact {
            self.updateSpacersIfNeeded(show: false)
            self.collectionViewWidthConstraint?.constant = self.view.frame.width - (2.0 * navButtonWidth)
        } else {
            var reqItemsCount = maxToShow
            if maxToShow > self.dataSourceItems.count {
                reqItemsCount = self.dataSourceItems.count
            }
            self.collectionViewWidthConstraint?.constant = CGFloat(reqItemsCount) * deskToolWidth
        }
        self.view.layoutIfNeeded()
        if self.dataSourceItems.count <= maxToShow {
            self.updateSpacersIfNeeded(show: true)
            self.updateNavButtons(show: false)
            self.collectionView.isScrollEnabled = false
        } else {
            self.updateSpacersIfNeeded(show: false)
            self.updateNavButtons(show: true)
            self.collectionView.isScrollEnabled = true
        }
        runInMainThread(0.1) {
            self.updateCurrentStatusOfNavButtons()
        }
    }
}

private extension FTToolbarCenterPanelController {
    private func updateSpacersIfNeeded(show: Bool) {
        if self.screenMode != .shortCompact {
            self.leftSpacer?.isHidden = !show
            self.rightSpacer?.isHidden = !show
        }
    }

    private func updateNavButtons(show: Bool) {
        self.leftNavBtn?.isHidden = !show
        self.rightNavBtn?.isHidden = !show
    }
    
    private func addObservers() {
        self.customToolbarObserver = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: notifyToolbarCustomization)
                                               , object: nil, queue: nil) { [weak self] (_) in
            runInMainThread {
                guard let strongSelf = self else {
                    return
                }
                let currentSavedItems = FTCurrentToolbarSection().displayTools
                if strongSelf.dataSourceItems != currentSavedItems {
                    strongSelf.updateCenterPanel()
                    strongSelf.collectionView.collectionViewLayout.invalidateLayout()
                    strongSelf.collectionView.reloadData()
                }
            }
        }
    }

    @IBAction func leftBtnTapped(_ sender: Any) {
        if self.collectionView.contentOffset.x > 0.0 {
            self.disableNavButtons()
            let reqOffsetX = self.collectionView.contentOffset.x - self.deskToolWidth
            let yOffset = self.collectionView.contentOffset.y
            self.collectionView.setContentOffset(CGPoint(x: reqOffsetX, y: yOffset), animated: true)
            self.updateCurrentStatusOfNavButtons()
            FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.toolbar_left_arrow_tap)
        }
    }

    @IBAction func rightBtnTapped(_ sender: Any) {
        if self.collectionView.contentOffset.x < self.collectionView.contentSize.width - self.collectionView.frame.width {
            self.disableNavButtons()
            let reqOffsetX = self.collectionView.contentOffset.x + self.deskToolWidth
            let yOffset = self.collectionView.contentOffset.y
            self.collectionView.setContentOffset(CGPoint(x: reqOffsetX, y: yOffset), animated: true)
            self.updateCurrentStatusOfNavButtons()
            FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.toolbar_right_arrow_tap)
        }
    }

     func disableNavButtons() {
        self.leftNavBtn?.isEnabled = false
        self.rightNavBtn?.isEnabled = false
    }

     func updateCurrentStatusOfNavButtons() {
        var toEnableLeft: Bool = false
        var toEnableRight: Bool = false
        if(self.collectionView.contentOffset.x >= self.collectionView.contentSize.width - self.collectionView.frame.width) {
            toEnableRight = false
        } else {
            toEnableRight = true
        }
        if self.collectionView.contentOffset.x > 0.0 {
            toEnableLeft = true
        } else {
            toEnableLeft = false
        }
        self.leftNavBtn?.isEnabled = toEnableLeft
        self.rightNavBtn?.isEnabled = toEnableRight
    }
}

// For outside world
extension FTToolbarCenterPanelController {
    func getSourceView(for btnType: FTDeskCenterPanelTool) -> UIView {
        var reqView: UIView = self.view
        var indexPath = IndexPath(row: 0, section: 0)
        if let index = self.dataSourceItems.firstIndex(where: { type in
            type == btnType
        }) {
            indexPath.row = index
        }
        if let cell = self.collectionView.cellForItem(at: indexPath) {
            reqView = cell
        }
        return reqView
    }
}

extension FTToolbarCenterPanelController: FTCenterPanelCollectionViewDelegate {
    func getScreenMode() -> FTScreenMode {
        return self.screenMode
    }
    
    func currentDeskMode() -> RKDeskMode? {
        return self.delegate?.currentDeskMode()
    }
    
    func isZoomModeEnabled() -> Bool {
        return self.delegate?.isZoomModeEnabled() ?? false
    }
    
    func maxCenterPanelItemsToShow() -> Int {
        return self.delegate?.maxCenterPanelItemsToShow() ?? 0
    }
    
    func didTapCenterPanelButton(type: FTDeskCenterPanelTool, sender: UIView) {
        self.delegate?.didTapCenterPanelButton(type: type, sender: sender)
    }
    
    func collectionViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.updateCurrentStatusOfNavButtons()
    }

    func collectionViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.updateCurrentStatusOfNavButtons()
        FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.toolbar_tools_swipe)

    }

    func collectionViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.updateCurrentStatusOfNavButtons()
            FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.toolbar_tools_swipe)
        }
    }

    func collectionViewDidScroll(_ scrollView: UIScrollView) {
        self.disableNavButtons()
    }

    func collectionViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let currentOffsetX = scrollView.contentOffset.x + (velocity.x * 300.0)
        var nearstOffsetX: CGFloat = 0.0
        if currentOffsetX <= 0.0 {

        } else if currentOffsetX >= scrollView.contentSize.width - scrollView.bounds.width {
            nearstOffsetX = scrollView.contentSize.width - scrollView.bounds.width
        } else {
            let cellWidth = Int(deskToolWidth)
            nearstOffsetX = CGFloat(self.roundUp(value: Int(currentOffsetX), divisor: cellWidth))
        }
        targetContentOffset.pointee.x = CGFloat(nearstOffsetX)
    }

    private func roundUp(value: Int, divisor: Int) -> Int {
        let modulo = value % divisor
        var multiplier = value / divisor
        if modulo > divisor/2 {
            multiplier += 1
        }
        return divisor * multiplier
    }
}

extension FTToolbarCenterPanelController {
    func addObserverForScrollDirection() {
        NotificationCenter.default.addObserver(forName: .pageLayoutWillChange,
                                                 object: nil,
                                                 queue: nil)
          { [weak self] (_) in
              self?.collectionView.reloadData()
         }
    }
    
    func setUpTipForNewFeatures() {
        if #available(iOS 17.0, *) {
            let newFeautres = NewFeatures()
            Task { @MainActor in
                for await shouldDisplay in newFeautres.shouldDisplayUpdates {
                    if shouldDisplay {
                        let controller = TipUIPopoverViewController(newFeautres, sourceItem: self.collectionView)
                        controller.view.backgroundColor = UIColor.init(hexString: "#474747")
                        controller.viewStyle = CustomTiPView()
                        present(controller, animated: true)
                    } else if presentedViewController is TipUIPopoverViewController {
                        dismiss(animated: true)
                    }
                }
            }
        } else {
            debugPrint("Using Lower versions then Ios 17")
        }
        
    }
    
}
