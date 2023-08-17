//
//  FTWebClipViewController.swift
//  Noteshelf
//
//  Created by Mahesh on 27/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import WebKit
import Reachability

protocol FTWebClipControllerDelegate: NSObjectProtocol {
    func didCaptureScreenShot(screenShot: UIImage?, clipUrlString: String?)
}

class FTWebClipViewController: UIViewController {
    weak var delegate: FTWebClipControllerDelegate?

    @IBOutlet private weak var webView: WKWebView!
    @IBOutlet private weak var searchTextFiled: UITextField?
    @IBOutlet private weak var textFiledTopConstraint: NSLayoutConstraint?
    @IBOutlet private weak var safariBtn: UIButton?
    @IBOutlet private weak var lblInfo: UILabel!
    @IBOutlet private weak var imgInfo: UIImageView!
    @IBOutlet private weak var insertBtn: UIBarButtonItem!
    @IBOutlet private weak var cancelBtn: UIBarButtonItem!
    @IBOutlet private weak var textFiledHeightConstraint: NSLayoutConstraint?
    
    @IBOutlet weak var errorStackview: UIStackView!
    var clipUrlString: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configDefaultUI()
        if clipUrlString != nil {
            configSearchUI()
            self.searchTextFiled?.becomeFirstResponder()
        }
    }
    
    //MARK:-  Private methods
    private func configDefaultUI() {
        self.webView.isHidden = true
        self.errorStackview.isHidden = true
        self.insertBtn.isEnabled = false
        self.insertBtn.title = "newnotebook.webclip.insert".localized
        self.cancelBtn.title = "cancel".localized
        self.insertBtn.isEnabled = false
        let navItemFont = UIFont.appFont(for: .regular, with: 17.0)
        self.insertBtn.setTitleTextAttributes([.font: navItemFont], for: .normal)
        self.cancelBtn.setTitleTextAttributes([.font: navItemFont], for: .normal)
        // Create a padding view for padding on left
        searchTextFiled?.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: searchTextFiled!.frame.height))
        searchTextFiled?.leftViewMode = .always
        self.lblInfo.text = "newnotebook.webclip.webclipinfo".localized
        self.lblInfo?.font = UIFont.clearFaceFont(for: .regular, with: 20.0)
        self.imgInfo?.image = UIImage(named: "webClip_header")
        self.safariBtn?.titleLabel?.text = "newnotebook.webclip.gotoSafari".localized
    }
    
    private func configSearchUI() {
        self.webView.isHidden = false
        safariBtn?.isHidden = true
        lblInfo.isHidden = true
        imgInfo.isHidden = true
        shouldAnimate(true)
        configWebView(with: clipUrlString)
        textFiledHeightConstraint?.constant = 39.0
    }
    
    private func configWebView(with clipUrl: String?) {
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        if let strClipURL = clipUrl, let url = URL(string: strClipURL) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    override var shouldAvoidDismissOnSizeChange: Bool {
        return true
    }
    
    private func shouldAnimate(_ anim: Bool) {
        if anim {
            UIView.animate(withDuration: 0.3) {
                self.shouldAnimate(false)
                self.view.layoutIfNeeded()
            }
            self.textFiledTopConstraint?.constant = -(24 + 90 + lblInfo.frame.height)
        }
    }
    
    //MARK:- Presentation
    class func showWebClip(overViewController viewController: UIViewController,
                            defaultURLString: String? = nil,
                           withDelegate delegate: FTWebClipControllerDelegate) {
        let storyboard = UIStoryboard.init(name: "FTDocumentEntity", bundle: nil);
        guard let webClipViewController  = storyboard.instantiateViewController(withIdentifier: "FTWebClipViewController") as? FTWebClipViewController else {
            fatalError("Programmer error, Couldnot find FTWebClipViewController")
        }
        webClipViewController.delegate = delegate
        webClipViewController.clipUrlString = defaultURLString
        viewController.ftPresentFormsheet(vcToPresent: webClipViewController)
    }
    
    //MARK:- Actions
    @IBAction func didTappedOnCancel(_ sender: Any?) {
        self.dismiss(animated: true)
    }
    
    @IBAction func didTapOnInsert(_ sender: Any?) {
        guard self.view != nil else {
            return
        }
        let snapShot = WKSnapshotConfiguration()
        self.webView.takeSnapshot(with: snapShot) { image, error in
            self.dismiss(animated: true) {
                if error == nil {
                    var urlString = self.searchTextFiled?.text
                    if urlString == nil {
                        if let webUrl = self.webView.url?.absoluteString {
                            urlString = webUrl
                        }
                    }
                    self.delegate?.didCaptureScreenShot(screenShot: image, clipUrlString: urlString)
                } else {
                    FTCLSLog(error?.localizedDescription ?? "")
                }
            }
        }
    }
    
    @IBAction func tapOnSafari(_ sender: Any?) {
        guard let url = URL(string: webClipDefaultURL) else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
        self.dismiss(animated: true)
    }
    
}


extension FTWebClipViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let txt = textField.text {
            if txt.isEmpty {
                self.configSearchUI()
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let txt = textField.text {
            if txt.isEmpty == false {
                if clipUrlString != txt {
                    if let request = txt.getUrlRequestFromString() {
                        webView.load(request)
                    }
                }
            }
        }
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let reachability: Reachability = Reachability.forInternetConnection()
        let status: NetworkStatus = reachability.currentReachabilityStatus();
        if status == NetworkStatus.NotReachable {
            errorStackview.isHidden = false
            self.webView.isHidden = true
        }else{
            errorStackview.isHidden = true
            self.webView.isHidden = false
            if let txt = textField.text {
                if txt.isEmpty == false {
                    if clipUrlString != txt {
                        if let request = txt.getUrlRequestFromString() {
                            webView.load(request)
                        }
                    }
                }
            }
        }
    }
}

extension FTWebClipViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if let url = webView.url?.absoluteString {
            searchTextFiled?.text = url
            self.clipUrlString = url
            self.insertBtn.isEnabled = true
        }
    }
}
