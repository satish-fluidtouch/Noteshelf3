//
//  FTTemplateWebViewScollController.swift
//  FTTemplatesNewUI
//
//  Created by Narayana on 17/05/24.
//

import WebKit
import FTCommon

protocol FTTemplateStoryDelegate: AnyObject {
    func getStoryFrameWrtoSplitController(_ story: FTTemplateStory) -> CGRect?
}

class FTTemplateWebViewScollController: UIViewController {
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var imgView: UIImageView!
    @IBOutlet private weak var webView: WKWebView!

    private weak var closeBtn: UIButton?
    private var visualEffectView: UIVisualEffectView?

    private let disableBounceScriptString = "var meta = document.createElement('meta');" +
    "meta.name = 'viewport';" +
    "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';" +
    "var head = document.getElementsByTagName('head')[0];" +
    "head.appendChild(meta);"

    private var story: FTTemplateStory?
    private let animDuration: CGFloat = 0.3
    private var delegate: FTTemplateStoryDelegate?

    // constarints
    @IBOutlet private weak var contentTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imgViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var webViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var contentCenterXConstraint: NSLayoutConstraint!
    @IBOutlet private weak var contentEqualWidthConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.contentInsetAdjustmentBehavior = .never
        self.visualEffectView = self.view.addVisualEffectBlur(style: .light, cornerRadius: 0.0)
        self.visualEffectView?.alpha = 0.0
        self.loadWebUrl()
        self.configWebView()
    }

    @objc func closeBtnTapped() {
        self.animateWebClosePreview()
    }
    
    public static func showFromViewController(_ viewController: UIViewController, with story: FTTemplateStory, delegate: FTTemplateStoryDelegate){
        if let templateWebController = UIStoryboard.init(name: "FTTemplatesStore", bundle: storeBundle).instantiateViewController(withIdentifier: "FTTemplateWebViewScollController") as? FTTemplateWebViewScollController {
             templateWebController.story = story
            templateWebController.delegate = delegate
            templateWebController.view.frame = viewController.view.bounds
            viewController.add(templateWebController);
            viewController.view.addSubview(templateWebController.view)
            templateWebController.animateWebOpenPreview()
        }
    }
}

extension FTTemplateWebViewScollController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        runInMainThread(0.1) {
            self.webViewHeightConstraint?.constant = webView.scrollView.contentSize.height
            self.view.layoutIfNeeded()
        }
    }
}

private extension FTTemplateWebViewScollController {
    func configWebView() {
        self.webView.navigationDelegate = self
        self.webView.scrollView.maximumZoomScale = 1.0
        self.webView.scrollView.minimumZoomScale = 1.0
        self.webView.scrollView.bounces = false
        self.webView.scrollView.bouncesZoom = false
        self.webView.scrollView.isScrollEnabled = false

        let script1: WKUserScript = WKUserScript(source: disableBounceScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let userContentController: WKUserContentController = WKUserContentController()
        let conf = WKWebViewConfiguration()
        conf.userContentController = userContentController
        self.webView.configuration.userContentController.addUserScript(script1)
    }

    func animateWebOpenPreview() {
        guard let templateStory = self.story, let initialFrame = self.delegate?.getStoryFrameWrtoSplitController(templateStory) else {
            return
        }
        self.contentCenterXConstraint.constant = 0.0  - self.view.frame.size.width/2 + initialFrame.origin.x + initialFrame.width/2
        self.contentTopConstraint.constant = initialFrame.origin.y
        self.imgViewHeightConstraint?.constant = initialFrame.height
        let widthMultiplier = initialFrame.width/self.view.frame.width
        self.contentEqualWidthConstraint = self.contentEqualWidthConstraint.getUpdatedConstraint(byApplying: widthMultiplier)
        self.webViewHeightConstraint?.constant = 0.0

        self.view.layoutIfNeeded()

        self.imgView.image = UIImage(named: templateStory.largeImageName, in: storeBundle, with: nil)
        self.imgView?.layer.contentsRect = CGRect(x: templateStory.thumbnailRectXPercent, y: templateStory.thumbnailRectYPercent, width: templateStory.thumbnailRectWidthPercent, height: templateStory.thumbnailRectHeightPercent)
        self.setupCloseButton()
        self.closeBtn?.isHidden = true

        UIView.animate(withDuration: animDuration) {
            self.visualEffectView?.alpha = 1.0
            self.contentCenterXConstraint.constant = 0
            self.contentTopConstraint.constant = 100
            var multiplier: CGFloat = 0.7
            if !(self.parent?.isRegularClass() ?? true) {
                multiplier = 1.0
            }
            self.contentEqualWidthConstraint = self.contentEqualWidthConstraint.getUpdatedConstraint(byApplying: multiplier)
            self.imgView?.layer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: 1)
            self.imgViewHeightConstraint?.constant = 300.0
            self.webViewHeightConstraint?.constant = self.view.frame.height - 100

            self.view.layoutIfNeeded()
        } completion: { _  in
            self.closeBtn?.isHidden = false
        }
    }

    private func setupCloseButton() {
        let closeButton = UIButton()
        closeButton.setImage(UIImage(named: "close", in: storeBundle, with: nil), for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeBtnTapped), for: .touchUpInside)
        self.view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            closeButton.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -24),
            closeButton.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24)
        ])
        self.closeBtn = closeButton
    }

    func animateWebClosePreview() {
        guard let templateStory = self.story, let initialFrame = self.delegate?.getStoryFrameWrtoSplitController(templateStory) else {
            return
        }
        UIView.animate(withDuration: animDuration) {
            self.visualEffectView?.alpha = 0.0
            self.closeBtn?.isHidden = true
            self.contentCenterXConstraint.constant = 0.0  - self.view.frame.size.width/2 + initialFrame.origin.x + initialFrame.width/2
            self.contentTopConstraint.constant = initialFrame.origin.y
            let widthMultiplier = initialFrame.width/self.view.frame.width
            self.contentEqualWidthConstraint = self.contentEqualWidthConstraint.getUpdatedConstraint(byApplying: widthMultiplier)
            self.webViewHeightConstraint?.constant = 0.0
            self.imgViewHeightConstraint?.constant = initialFrame.height
            self.imgView?.layer.contentsRect = CGRect(x: templateStory.thumbnailRectXPercent, y: templateStory.thumbnailRectYPercent, width: templateStory.thumbnailRectWidthPercent, height: templateStory.thumbnailRectHeightPercent)
            self.view.layoutIfNeeded()
        } completion: { _  in
            self.closeBtn?.removeFromSuperview()
            self.view.removeFromSuperview()
            self.removeFromParent()
        }
    }
    func loadWebUrl() {
        if let url = URL(string: "https://www.google.com") {
            self.webView.load(URLRequest(url: url))
        }
    }
}
