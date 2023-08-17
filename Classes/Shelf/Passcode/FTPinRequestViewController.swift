//
//  FTPinRequestViewController.swift
//  Noteshelf
//
//  Created by Prabhu on 7/5/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

typealias FTPinCompletionCallBack = (_ pin: String?,_ success: Bool,_ cancelled: Bool) -> Void;

protocol FTPasswordCallbackProtocol: AnyObject {
    func cancelButtonAction()
    func didFinishVerification(onController controller: UIViewController, currentPassword: String)
}

extension FTPasswordCallbackProtocol {
    func didFinishVerification(onController controller: UIViewController, currentPassword: String = "") {
        didFinishVerification(onController: controller, currentPassword: currentPassword)
    }
}

protocol FTPinRequestViewControllerDelegate:FTPasswordCallbackProtocol {
    var  pinRequestController: FTPinRequestViewController? {get set}
    var  pinRequestCompletionBLock:FTPinCompletionCallBack? {get set}
    func dismisAuthScreen(completion:@escaping () -> Void)
    func showAuthScreen(title:String?,completion:@escaping(_ authPin:String?, _ isTouchIDEnabled: Bool) -> Void)
}

class FTPinRequestViewController: FTPasswordKeypadController, UITextViewDelegate,UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    override var shouldAvoidDismissOnSizeChange: Bool {
        return true;
    }
    
    let rowIndexForTouchID = 1;

    var showTouchIDOptions = true;
    private  weak var delegate:FTPinRequestViewControllerDelegate?
    @IBOutlet var tableView: UITableView!
    @IBOutlet var footerView: FTPasswordFooterView!
    
    var noteBookname:String! = ""
    internal var pinRequestCompletionBLock:FTPinCompletionCallBack?
    
    var attemptsCounter:UInt = 0
    let ftDidAuthenticateSuccessfully = Notification.Name("FTDidAuthenticateSuccessfully")
    let ftDidFailedToAuthenticate = Notification.Name("FTDidFailedToAuthenticate")
    
    private var isTouchIDEnabledByUser = false;

    var password:String? {
        return (self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? FTPassWordNormalCell)?.textFeild.text
    }
    var hint:String?
    var isTouchIDEnabled:Bool {
        if(self.showTouchIDOptions) {
            return FTBiometricManager.shared().isTouchIDEnabled() && (self.footerView.touchIDSwitch?.isOn ?? false)
        }
        return false
    }
    
    //MARK:- UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerForKeyboardDidShowNotification(scrollView: self.tableView)
        self.registerForKeyboardWillHideNotification(scrollView: self.tableView)
        self.footerView.biometricView.layer.cornerRadius = 8.0
        self.footerView.canShowBiometricOption = (self.isTouchIDEnabled && FTBiometricManager.shared().isTouchIDEnabled())
        self.footerView.lblInfoMessage?.text = String(format: NSLocalizedString("EnterThePasswordFor", comment: "Enter the password for \"%@\"."), self.noteBookname)
        self.footerView.lblUseTouchID?.text = FTBiometricManager.shared().openWithBiometryCaption()
        self.footerView.lblUseTouchID?.addCharacterSpacing(kernValue: -0.41)
        self.footerView.touchIDSwitch?.addTarget(self,
                                                action: #selector(self.toggleIsTouchIDEnabled),
                                                for: UIControl.Event.valueChanged);
        self.footerView.touchIDSwitch?.isOn = self.isTouchIDEnabledByUser;

        NotificationCenter.default.addObserver(self, selector: #selector(didSucceedAuthentication), name: ftDidAuthenticateSuccessfully , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didFailedToAuthentication(notification:)), name: ftDidFailedToAuthenticate, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNavigationBar(title: NSLocalizedString("Password", comment: ""))
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        self.pinRequestCompletionBLock = nil
        super.dismiss(animated: flag, completion: completion);
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK:- Presentation
    class func show(from viewController: UIViewController,
                    delegate: FTPinRequestViewControllerDelegate? = nil,
                    title: String!,
                    onCompletion: @escaping FTPinCompletionCallBack) -> FTPinRequestViewController {
        let storyBoard =  UIStoryboard(name: "FTPasswordSettings", bundle: nil)
        guard let pinRequestController = storyBoard.instantiateViewController(withIdentifier: "FTPinRequestViewController") as? FTPinRequestViewController else {
            fatalError("Programmer error - couldnot find FTPinRequestViewController")
        }
        pinRequestController.delegate = delegate;
        pinRequestController.noteBookname = title;
        pinRequestController.pinRequestCompletionBLock = onCompletion
        
        let navController = UINavigationController(rootViewController: pinRequestController)
        navController.presentationController?.delegate = pinRequestController
        viewController.ftPresentFormsheet(vcToPresent: navController, hideNavBar: false)
        return pinRequestController;
    }
    
    //MARK:- Actions
    override func leftNavBtnTapped(_ sender: UIButton) {
        self.pinRequestCompletionBLock?(nil, false,true);
    }
    
    override func rightNavBtnTapped(_ sender: UIButton) {
        if self.pinRequestCompletionBLock != nil {
            if let text = self.password {
                self.pinRequestCompletionBLock?(text, self.isTouchIDEnabled,false)
            }
        }
    }
    
    //MARK:- UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 11
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FTPassWordNormalCell", for: indexPath) as? FTPassWordNormalCell else {
            fatalError("Programmer error - couldnot find FTPassWordNormalCell")
        }
        cell.textFeild.setStyledPlaceHolder(NSLocalizedString("Required", comment: "Required"), style: .style1);
        cell.textFeild.clearButtonMode = .never
        cell.textFeild.textAlignment = .right
        cell.textFeild.isSecureTextEntry = true
        if indexPath.row == 0 {
            cell.leftLabel.text = NSLocalizedString("Password", comment: "Password")
            cell.leftLabel.addCharacterSpacing(kernValue: -0.41)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            if let cell = cell as? FTPassWordNormalCell {
                if false == cell.textFeild.isFirstResponder {
                    DispatchQueue.main.async {
                        cell.textFeild.becomeFirstResponder()
                    }
                }
            }
        }
    }
    
    //MARK:- Authentication
    @objc func didSucceedAuthentication() {
        self.navigationController?.presentedViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func didFailedToAuthentication(notification:Notification?) {
        
        weak var weakSelf = self;
        var message : String? = NSLocalizedString("PleaseEnterValidPassword", comment: "Please Enter valid password");
        
        attemptsCounter += 1
        if attemptsCounter == 3 {
            attemptsCounter = 0
            //show hint
            message = nil;
            if let error = notification?.object as? NSError {
                if let hint = error.userInfo["hint"] as? String, false == hint.isEmpty {
                    message = "Hint: " + hint
                }
            }
        }
            
        let alert = UIAlertController(title: NSLocalizedString("IncorrectPassword", comment: "Incorrect Password"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: { (action) in
            let cell = (weakSelf?.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? FTPassWordNormalCell);
            cell?.textFeild.text = nil
            cell?.textFeild.becomeFirstResponder()
        }));
        self.present(alert, animated: true, completion: nil)
    }
    //MARK:- UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.delegate?.didFinishVerification(onController: self)
        if nil == self.delegate {
            if self.pinRequestCompletionBLock != nil {
                if let text = self.password {
                    self.pinRequestCompletionBLock?(text, self.isTouchIDEnabled,false)
                }
            }
        }
        return true
    }

    @objc private func toggleIsTouchIDEnabled() {
        self.isTouchIDEnabledByUser = !self.isTouchIDEnabledByUser;
    }

}

extension FTPinRequestViewController: UIAdaptivePresentationControllerDelegate {
  func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
       return false;
  }
}
