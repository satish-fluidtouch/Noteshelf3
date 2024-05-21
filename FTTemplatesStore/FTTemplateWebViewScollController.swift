//
//  FTTemplateWebViewScollController.swift
//  FTTemplatesNewUI
//
//  Created by Narayana on 17/05/24.
//

import WebKit
import FTCommon

class FTTemplateWebViewScollController: UIViewController {
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var imgView: UIImageView!
    @IBOutlet private weak var webView: WKWebView!
    @IBOutlet private weak var closeBtn: UIButton!

    private var visualEffectView: UIVisualEffectView?
    private let disableBounceScriptString = "var meta = document.createElement('meta');" +
    "meta.name = 'viewport';" +
    "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';" +
    "var head = document.getElementsByTagName('head')[0];" +
    "head.appendChild(meta);"

    var headerImage: UIImage = UIImage(named: "story1_big", in: storeBundle, compatibleWith: nil)!
    var initialFrame: CGRect!
   
    private let animDuration: CGFloat = 5
    
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
        self.closeBtn.isHidden = true
        self.loadWebUrl()
        self.configWebView()
    }

    @IBAction func closeBtnTapped(_ sender: Any) {
        self.animateWebClosePreview()
    }
    
    public static func showFromViewController(_ viewController: UIViewController, with image: UIImage, initialFrame: CGRect){
        if let templateWebController = UIStoryboard.init(name: "FTTemplatesStore", bundle: storeBundle).instantiateViewController(withIdentifier: "FTTemplateWebViewScollController") as? FTTemplateWebViewScollController {
            // templateWebController.headerImage = image
            templateWebController.initialFrame = initialFrame
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
        self.contentCenterXConstraint.constant = 0.0  - self.view.frame.size.width/2 + self.initialFrame.origin.x + self.initialFrame.width/2
        self.contentTopConstraint.constant = self.initialFrame.origin.y
        self.imgViewHeightConstraint?.constant = self.initialFrame.height
        let widthMultiplier = self.initialFrame.width/self.view.frame.width
        self.contentEqualWidthConstraint = self.contentEqualWidthConstraint.getUpdatedConstraint(byApplying: widthMultiplier)
        self.webViewHeightConstraint?.constant = 0.0

        self.view.layoutIfNeeded()

        self.imgView.image = headerImage
        self.imgView?.layer.contentsRect = CGRect(x: 0.2, y: 0.45, width: 0.37, height: 0.43)
        
        UIView.animate(withDuration: animDuration) {
            self.visualEffectView?.alpha = 1.0
            self.contentCenterXConstraint.constant = 0
            self.contentTopConstraint.constant = 100
            self.contentEqualWidthConstraint = self.contentEqualWidthConstraint.getUpdatedConstraint(byApplying: 0.6)
            self.imgView?.layer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: 1)
            self.imgViewHeightConstraint?.constant = 300.0
            self.webViewHeightConstraint?.constant = self.view.frame.height - 100

            self.view.layoutIfNeeded()
        } completion: { _  in
            self.closeBtn.isHidden = false
        }
    }

    func animateWebClosePreview() {
        UIView.animate(withDuration: animDuration) {
            self.visualEffectView?.alpha = 0.0
            self.closeBtn.isHidden = true
            self.contentCenterXConstraint.constant = 0.0  - self.view.frame.size.width/2 + self.initialFrame.origin.x + self.initialFrame.width/2
            self.contentTopConstraint.constant = self.initialFrame.origin.y
            let widthMultiplier = self.initialFrame.width/self.view.frame.width
            self.contentEqualWidthConstraint = self.contentEqualWidthConstraint.getUpdatedConstraint(byApplying: widthMultiplier)
            self.webViewHeightConstraint?.constant = 0.0
            self.imgViewHeightConstraint?.constant = self.initialFrame.height
            self.imgView?.layer.contentsRect = CGRect(x: 0.2, y: 0.45, width: 0.37, height: 0.43)
            self.view.layoutIfNeeded()
        } completion: { _  in
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
