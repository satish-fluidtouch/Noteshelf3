//
//  FTWelcomeScreenViewController.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 08/04/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import AVFAudio

class FTClearFaceFontLabel: UILabel {
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize;
        size.width += 2;
        size.height += 2;
        return size;
    }
}

class FTWelcomeScreenViewController: UIViewController {
    private weak var previewController: FTWelcomePreviewViewController?
    @IBOutlet weak var titleLable: UILabel?;
    @IBOutlet weak var tapTileInfoLable: UILabel?;

    @IBOutlet weak var dismissButton: UIButton?;
    @IBOutlet weak var playPauseButton: UIButton?;

    @IBOutlet weak var subTitle: UILabel?;
    @IBOutlet private weak var topHeaderView: UIStackView?;

    private weak var selectedSlide: FTWelcomeItemViewController?;
    @IBOutlet private weak var headerConstraintTop: NSLayoutConstraint?;
    @IBOutlet private weak var footerConstraintBottom: NSLayoutConstraint?;
    @IBOutlet private weak var contentViewConstraintTop: NSLayoutConstraint?;

    @IBOutlet private weak var contentView: UIView?;

    @IBOutlet private weak var contentHeightConstraint: NSLayoutConstraint?;

    @IBOutlet private weak var scrollView1: UIScrollView?;
    @IBOutlet private weak var scrollView2: UIScrollView?;
    
    private var popUpOpenPlayer: AVAudioPlayer?;
    private var popUpClosePlayer: AVAudioPlayer?;
    private var bgAudioPlayer: AVAudioPlayer?

    private var onDismissBlock: (() -> Void)?
    
    private var isMuted = true;
    
    private var model = FTGetStartedItemViewModel();
    class func showWelcome(presenterController: UIViewController, onDismiss : (() -> Void)?) {
        let story = UIStoryboard(name: "FTWelcome", bundle: nil)
        let welcomeController = story.instantiateViewController(withIdentifier: "FTWelcomeScreenViewController") as! FTWelcomeScreenViewController
        welcomeController.onDismissBlock = onDismiss;
        welcomeController.modalPresentationStyle = .overFullScreen;
        welcomeController.modalTransitionStyle = .crossDissolve;
        presenterController.present(welcomeController, animated: true, completion: nil)
    }
    
    private var fontSize: CGFloat {
        guard !UIDevice.current.isPhone() else {
            return 36;
        }
        return (self.view.frame.width > 400) ? 52 : 36
    }
    
    private var itemSize: CGFloat {
        return (UIDevice.current.isPhone() ? 144 : 180)
    }
    
    override func updateViewConstraints() {
        let viewHeight = self.view.frame.size.height;
        
        let contentHeight = 2 * itemSize + 16 + (self.dismissButton?.frame.height ?? 0) + (self.topHeaderView?.frame.height ?? 0);
        let remainingHeight = (viewHeight - contentHeight) / 4;
               
        self.contentHeightConstraint?.constant = 2 * itemSize + 16;
        self.headerConstraintTop?.constant = remainingHeight;
        self.footerConstraintBottom?.constant = remainingHeight;
        self.contentViewConstraintTop?.constant = remainingHeight;
        super.updateViewConstraints()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                         
        self.contentView?.translatesAutoresizingMaskIntoConstraints = false
        
        self.dismissButton?.addShadow(CGSize(width: 0, height: 12), color: UIColor.appColor(.welcomeBtnColor), opacity: 0.24, radius: 16.0)
        self.contentView?.addShadow(CGSize(width: 0, height: 30), color: UIColor.appColor(.WelcomeContentShadowColor), opacity: 0.12, radius: 30)

        self.titleLable?.textColor = UIColor.label;
        self.titleLable?.text = self.model.headerTopTitle
        self.updateUI();
        
        self.tapTileInfoLable?.text = "welcome.taptileinfo".localized
        self.tapTileInfoLable?.textColor = UIColor.label.withAlphaComponent(0.5);
        
        self.dismissButton?.setAttributedTitle(NSAttributedString(string: model.btntitle, attributes: [
            .font : UIFont.clearFaceFont(for: .medium, with: 20)
            , .foregroundColor : UIColor.white
        ]), for: .normal);
        self.dismissButton?.backgroundColor = UIColor.appColor(.welcomeBtnColor)
        self.dismissButton?.layer.cornerRadius = 16;
        
        self.view.layoutIfNeeded();
        self.view.setNeedsUpdateConstraints();
        self.view.updateConstraintsIfNeeded()

        var itemsToLoad = [FTGetStartedViewItems]();
        itemsToLoad.append(contentsOf: model.getstartedList);
        itemsToLoad.append(contentsOf: model.getstartedList);
        
        self.loadGrids(itemsToLoad, contentView: self.scrollView1!)
        self.loadGrids(itemsToLoad, contentView: self.scrollView2!)
        
        var offset = self.scrollView2?.contentOffset ?? .zero;
        offset.x = self.scrollView2!.contentSize.width - self.scrollView2!.frame.width
        self.scrollView2?.contentOffset = offset;
        self.startAnimation();
        
        if !UIDevice.current.isPhone() {
            self.loadAudioFiles();
        }
        self.validatePlayPauseButton(self.view.frame.size);
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true;
    }
    
    private func validatePlayPauseButton(_ size: CGSize) {
        var shouldHide = false;
        if UIDevice.current.isIphone() {
            shouldHide = true;
        }
        else if let dismissButtonframe = self.dismissButton?.frame.width {
            let availableWidth = (size.width - dismissButtonframe);
            shouldHide = (availableWidth * 0.5) < 100;
        }
        else if self.bgAudioPlayer == nil {
            shouldHide = true;
        }
        self.playPauseButton?.isHidden = shouldHide;
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator);
        let isPaused = self.displayLink.isPaused;
        self.stopAnimation()
        coordinator.animate { context in
            self.view.setNeedsUpdateConstraints();
            self.view.updateConstraintsIfNeeded();
            self.view.layoutIfNeeded()
            self.previewController?.updateViewConstraintsOntransition()
            self.validatePlayPauseButton(size);
            self.updateUI();
        } completion: { _ in
            if !isPaused {
                self.startAnimation()
            }
        }
    }
  
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.sceneDidEnterForeground(_:)), name: UIApplication.sceneWillEnterForeground, object: self.sceneToObserve)
        NotificationCenter.default.addObserver(self, selector: #selector(self.sceneWillEnterBackground(_:)), name: UIApplication.sceneDidEnterBackground, object: self.sceneToObserve)
    }
    
    private func updateUI() {
        self.titleLable?.font = UIFont.clearFaceFont(for: .regular, with: fontSize)
        let attributedTet = NSMutableAttributedString(string: self.model.headerbottomfirstTitle, attributes: [.font : UIFont.clearFaceFont(for: .regular, with: fontSize),.foregroundColor : UIColor.label])
        let secondSet = NSAttributedString(string: self.model.headerbottomsecondTitle, attributes: [.font: UIFont.clearFaceFont(for: .regularItalic, with: fontSize),.foregroundColor : UIColor.label])
        attributedTet.append(secondSet)
        self.subTitle?.attributedText = attributedTet;
    }
    
    @IBAction func didToggelePlayPauseButton(_ sender: UIButton) {
        isMuted.toggle();
        self.playPauseButton?.isSelected = !isMuted;
        if isMuted {
            self.bgAudioPlayer?.volume = 0;
            track("Welcome_Audio", params: ["State": "Pause"], screenName: FTScreenNames.welcomeScreen);
        }
        else {
            if !(self.bgAudioPlayer?.isPlaying ?? false) {
                self.bgAudioPlayer?.play()
            }
            self.muteBackgroundMusic(false);
            track("Welcome_Audio", params: ["State": "Play"], screenName: FTScreenNames.welcomeScreen);
        }
    }
    
    @objc private func sceneDidEnterForeground(_ notification: Notification) {
        if nil == self.selectedSlide {
            self.startAnimation()
        }
        if !isMuted {
            if !(self.bgAudioPlayer?.isPlaying ?? false) {
                self.bgAudioPlayer?.play()
            }
            self.muteBackgroundMusic(false)
        }
    }
    
    @objc private func sceneWillEnterBackground(_ notification: Notification) {
        self.stopAnimation()
        self.muteBackgroundMusic(true);
    }
    
    @IBAction func didTapOnDismiss(_ sender: UIButton?) {
        UserDefaults.standard.set(true, forKey: WelcomeScreenViewed)
        UserDefaults.standard.synchronize();
        self.muteBackgroundMusic(true)
        self.dismiss(animated: true) {
            self.displayLink.invalidate();
            self.onDismissBlock?();
            self.onDismissBlock = nil
        }
    }
                
    private lazy var displayLink: CADisplayLink = {
        let displayLink = CADisplayLink(target: self, selector: #selector(self.updateContent(_:)));
        displayLink.preferredFrameRateRange = CAFrameRateRange(minimum: 20, maximum: 40);
        displayLink.add(to: RunLoop.current, forMode: RunLoop.Mode.default);

        return displayLink;
    }();
    
    private func startAnimation() {
        self.displayLink.isPaused = false
    }
    
    private func stopAnimation() {
        self.displayLink.isPaused = true
    }
    
    @objc private func updateContent(_ displayLInk: CADisplayLink) {
        guard let _scrollview1 = self.scrollView1, let _scrollview2 = self.scrollView2 else {
            return;
        }
        
        var offset = _scrollview1.contentOffset;
        offset.x += 1;
        if offset.x > _scrollview1.contentSize.width - _scrollview1.frame.width {
            offset.x = 0;
        }
        _scrollview1.contentOffset = offset;
        
        var offset1 = _scrollview2.contentOffset;
        offset1.x -= 1;
        if offset1.x < 0 {
            offset1.x = _scrollview2.contentSize.width - _scrollview2.frame.width;
        }
        offset1.x = max(offset1.x,0)
        _scrollview2.contentOffset = offset1;
    }
        
    private  func loadGrids( _ items: [FTGetStartedViewItems], contentView: UIScrollView) {
        var previousFrame = CGPoint.zero;
        items.forEach { eachItem in
            let item = FTWelcomeItemViewController.welcomeItemComtroller(eachItem)
            item.delegate = self;
            var frame = item.view.frame
            frame.origin = CGPoint(x:previousFrame.x,y:0);
            frame.size = eachItem.contentSize(self.itemSize)
            item.view.frame = frame
            
            self.addChild(item);
            contentView.addSubview(item.view);
            previousFrame.x = frame.maxX + 16;
        }
        contentView.contentSize = CGSize(width: previousFrame.x - 16, height: contentView.frame.height)
    }
}

extension FTWelcomeScreenViewController: FTWelcomePreviewDelegate {
    func welcomePreviewDidClose(_ preview: FTWelcomePreviewViewController) {
        guard let slide = self.selectedSlide else {
            return;
        }
        
        self.playPopupCloseSound();

        let frame = self.frame(for: slide)
        preview.dismissPreivew(to: frame,itemSize: self.itemSize) {
            preview.removeFromParent()
            preview.view.removeFromSuperview();
            self.selectedSlide?.setAsPreviewed(false)
            self.selectedSlide = nil;
            self.previewController = nil;
            self.startAnimation();
        }
    }
}

extension FTWelcomeScreenViewController: FTWelcomeItemDelegate {
    func welcomeItem(_ controller: FTWelcomeItemViewController, didTapOnItem item: FTGetStartedViewItems) {
        self.playPopupOpenSound()
        
        let previewController = FTWelcomePreviewViewController.welcomeItemComtroller(item);
        previewController.referenceContentView = self.contentView;
        
        let frame = self.frame(for: controller)
        previewController.delegate = self;
        self.addChild(previewController);
        previewController.view.frame = self.view.bounds
        previewController.view.addFullConstraints(self.view);
        selectedSlide = controller;
        self.previewController = previewController;
        
        controller.setAsPreviewed(true)
        
        previewController.showPreview(from: frame,itemSize: self.itemSize)
        self.stopAnimation();
        track("Welcome_Tile_Open", params: ["Tile": item.displayTitle], screenName: FTScreenNames.welcomeScreen);
    }
}


private extension FTWelcomeScreenViewController {
    func frame(for controller: FTWelcomeItemViewController) -> CGRect {
        var frame = controller.view.frame;
        if let scrollView = controller.view.superview as? UIScrollView {
            let offset = scrollView.contentOffset;
            frame.origin.x -= offset.x;
            frame.origin.y -= offset.y;
            frame.origin.y += scrollView.frame.origin.y;
            frame.origin.y += (scrollView.superview?.frame.origin.y ?? 0);
        }
        return frame;
    }
}

private extension FTWelcomeScreenViewController {
    func loadAudioFiles() {
        DispatchQueue.global().async {
            if let url = Bundle.main.url(forResource: "ambient loop", withExtension: "mp3")
                ,let popup_open = Bundle.main.url(forResource: "popup_open", withExtension: "mp3")
                ,let popup_close = Bundle.main.url(forResource: "popup_close", withExtension: "mp3")
            {
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback)
                    try AVAudioSession.sharedInstance().setActive(true)
                    let avplayer = try AVAudioPlayer(contentsOf: url)
                    avplayer.numberOfLoops = -1;
                    avplayer.volume = 0;
                    avplayer.prepareToPlay();

                    let buttonEffectPlayer = try AVAudioPlayer(contentsOf: popup_open)
                    buttonEffectPlayer.prepareToPlay();
                    
                    let popClosePlayer = try AVAudioPlayer(contentsOf: popup_close)
                    popClosePlayer.prepareToPlay();

                    runInMainThread {
                        self.popUpOpenPlayer = buttonEffectPlayer;
                        self.popUpOpenPlayer?.volume = 1.0

                        self.popUpClosePlayer = popClosePlayer;
                        self.popUpClosePlayer?.volume = 1.0

                        self.bgAudioPlayer = avplayer
                        self.bgAudioPlayer?.play();
                        if !self.isMuted {
                            self.muteBackgroundMusic(false)
                        }
                    }
                }
                catch {
                    debugLog("error : \(error)");
                }
            }
        }
    }
    
    func playPopupOpenSound() {
        if !isMuted {
            self.popUpOpenPlayer?.currentTime = TimeInterval(0)
            self.popUpOpenPlayer?.play();
        }
    }
    
    func playPopupCloseSound() {
        if !isMuted {
            self.popUpClosePlayer?.currentTime = TimeInterval(0)
            self.popUpClosePlayer?.play();
        }
    }
    
    func muteBackgroundMusic(_ mute: Bool) {
        if mute {
            self.bgAudioPlayer?.setVolume(0, fadeDuration: 1)
        }
        else {
            if !(self.bgAudioPlayer?.isPlaying ?? false) {
                self.bgAudioPlayer?.play();
            }
            self.bgAudioPlayer?.setVolume(0.5, fadeDuration: 1);
        }
    }
}

extension UIView {
    func addShadow(_ offset: CGSize, color: UIColor, opacity: Float = 1.0,radius: CGFloat) {
        self.layer.shadowOffset = offset
        self.layer.shadowRadius = radius
        self.layer.shadowOpacity = opacity
        self.layer.shadowColor = color.cgColor
    }
}
