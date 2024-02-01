//
//  FTPasswordViewController.swift
//  Noteshelf
//
//  Created by Narayana on 11/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

let ftDidAuthenticateSuccessfully = Notification.Name("FTDidAuthenticateSuccessfully")
let ftDidFailedToAuthenticate = Notification.Name("FTDidFailedToAuthenticate")

enum FTPasswordCreation {
    case existingNotebook
    case newNotebook
}

enum FTPasswordFlow {
    case setPassword
    case changePassword
    
    var fieldCount: Int {
        if self == .setPassword {
            return 3
        }
        return 4
    }
    
    var fieldArray: [String] {
        if self == .setPassword {
            return ["Password".localized, "password.confirmpassword".localized, "Hint".localized]
        }
        return ["CurrentPassword".localized, "NewPassword".localized, "password.confirmpassword".localized, "Hint".localized]
    }
}

enum FTPasswordField {
    case setPassword
    case setVerifyPassword
    case setHint
    case currentPassword
    case newPassword
    case confirmPassword
    case changeHint
}

class FTPasswordViewController: FTPasswordKeypadController, FTCustomPresentable {
    var customTransitioningDelegate: FTCustomTransitionDelegate = FTCustomTransitionDelegate(with: .presentation)

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerView: FTPasswordHeaderView!
    @IBOutlet weak var footerView: FTPasswordFooterView!
    private let saveButton = UIButton()
    var passwordFlow: FTPasswordFlow = .setPassword
    var passwordCreation: FTPasswordCreation = .existingNotebook

    weak var delegate: FTPasswordCallbackProtocol?
    
    var isTouchIDEnabled:Bool {
        let isTouchEnabled: Bool = FTBiometricManager.shared().isTouchIDEnabled() && (footerView.touchIDSwitch?.isOn ?? false)
        return isTouchEnabled
    }

    // Used for change password flow
    var isTouchIDEnabledAtPresent = false
    var isTouchIDEnabledManually = false
    var toDisablePassword = false
    var newPassword: String?
    var attemptsCounter: UInt = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerForKeyboardDidShowNotification(scrollView: self.tableView)
        self.registerForKeyboardWillHideNotification(scrollView: self.tableView)
        self.headerView.configureHeader()
        self.configureEnablePwdView()
        self.configureNavigationBar()
        var toShowFooterView = false
        if passwordFlow == .changePassword || passwordCreation == .newNotebook {
            toShowFooterView = true
        }
        self.configureFooterView(toShow: toShowFooterView)
        
        if self.passwordFlow == .changePassword {
            NotificationCenter.default.addObserver(self, selector: #selector(didSucceedAuthentication), name: ftDidAuthenticateSuccessfully , object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(didFailedToAuthentication(notification:)), name: ftDidFailedToAuthenticate, object: nil)
        }
    }

    private func configureEnablePwdView() {
        if passwordFlow == .setPassword && passwordCreation == .existingNotebook {
            self.headerView.enableSwitch?.isOn = false
        } else {
            self.headerView.enableSwitch?.isOn = true
        }
        self.headerView.enableSwitch?.addTarget(self,
                                                action: #selector(self.toggleRequirePasswordSwitch(sender:)),
                                                for: UIControl.Event.valueChanged)
    }
    private func validateFields() -> Bool {
        if passwordFlow == .setPassword {
            let index1: IndexPath = IndexPath(row: 0, section: 0)
            let index2: IndexPath = IndexPath(row: 1, section: 0)
            guard let rowPassword = self.tableView.cellForRow(at: index1) as? FTPassWordNormalCell,
                  let rowConfirmPassword = self.tableView.cellForRow(at: index2) as? FTPassWordNormalCell else {
                return false
            }
            return !(rowPassword.textFeild.text!.isEmpty) && !(rowConfirmPassword.textFeild.text!.isEmpty)
        } else {
            let index1: IndexPath = IndexPath(row: 0, section: 0)
            let index2: IndexPath = IndexPath(row: 1, section: 0)
            let index3: IndexPath = IndexPath(row: 2, section: 0)
            guard let rowPassword = self.tableView.cellForRow(at: index1) as? FTPassWordNormalCell,
                  let rowNewPassword = self.tableView.cellForRow(at: index2) as? FTPassWordNormalCell,
                  let rowConfirmPassword = self.tableView.cellForRow(at: index3) as? FTPassWordNormalCell else {
                return false
            }
            return !(rowPassword.textFeild.text!.isEmpty) && !(rowNewPassword.textFeild.text!.isEmpty) && !(rowConfirmPassword.textFeild.text!.isEmpty)
        }
    }
    private func configureNavigationBar(){

        saveButton.setTitle("password.save".localized, for: .normal)
        saveButton.titleLabel?.font = UIFont.appFont(for: .regular, with: 17)
        saveButton.setTitleColor(.appColor(.accent), for: .normal)
        saveButton.titleLabel?.addCharacterSpacing(kernValue: -0.41)
        saveButton.addTarget(self, action: #selector(rightNavBtnTapped(_ :)), for: .touchUpInside)

        let cancelButton = UIButton()
        cancelButton.setTitle("Cancel".localized, for: .normal)
        cancelButton.titleLabel?.font = UIFont.appFont(for: .regular, with: 17)
        cancelButton.setTitleColor(.appColor(.accent), for: .normal)
        cancelButton.titleLabel?.addCharacterSpacing(kernValue: -0.41)
        cancelButton.addTarget(self, action: #selector(leftNavBtnTapped(_:)), for: .touchUpInside)

        let rightBarBtnItem = UIBarButtonItem(customView: saveButton)
        let leftBarBtnItem = UIBarButtonItem(customView: cancelButton)
        self.navigationItem.rightBarButtonItem = rightBarBtnItem
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        saveButton.alpha = self.navigationItem.rightBarButtonItem?.isEnabled == true ? 1.0 : 0.5
        self.navigationItem.leftBarButtonItems = [leftBarBtnItem]
        self.navigationItem.title = self.passwordFlow == .changePassword ? "password.changePassword".localized : "Password".localized
        self.navigationController?.navigationItem.largeTitleDisplayMode = .never
    }
    
     func getRequiredFieldText(field: FTPasswordField) -> String {
        switch field {
        case .setPassword:
            if passwordFlow == .setPassword {
                return (self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? FTPassWordNormalCell)?.textFeild.text ?? ""
            }
        case .setVerifyPassword:
            if passwordFlow == .setPassword {
                return (self.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? FTPassWordNormalCell)?.textFeild.text ?? ""
            }
        case .setHint:
            if passwordFlow == .setPassword {
                return (self.tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? FTPassWordNormalCell)?.textFeild.text ?? ""
            }
        case .currentPassword:
            if passwordFlow == .changePassword {
                return (self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? FTPassWordNormalCell)?.textFeild.text ?? ""
            }
        case .newPassword:
            if passwordFlow == .changePassword {
                return (self.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? FTPassWordNormalCell)?.textFeild.text ?? ""
            }
        case .confirmPassword:
            if passwordFlow == .changePassword {
                return (self.tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? FTPassWordNormalCell)?.textFeild.text ?? ""
            }
        case .changeHint:
            if passwordFlow == .changePassword {
                return (self.tableView.cellForRow(at: IndexPath(row: 3, section: 0)) as? FTPassWordNormalCell)?.textFeild.text ?? ""
            }
        }
         return ""
    }
    
    private func configureFooterView(toShow: Bool) {
        if toShow {
            self.footerView.isHidden = false
            self.footerView.canShowBiometricOption = FTBiometricManager.shared().isTouchIDEnabled()
            self.footerView.lblInfoMessage?.text = "notebookSettings.password.info".localized
            self.footerView.lblUseTouchID?.text = FTBiometricManager.shared().openWithBiometryCaption()
            self.footerView.lblUseTouchID?.addCharacterSpacing(kernValue: -0.41)
            self.footerView.touchIDSwitch?.addTarget(self,
                                                    action: #selector(self.toggleIsTouchIDEnabled),
                                                    for: UIControl.Event.valueChanged);
            self.footerView.touchIDSwitch?.isOn = self.isTouchIDEnabledManually
            self.footerView.lockTitleLabel?.text = "LockNotebookOption".localized
            self.footerView.lockTitleLabel?.addCharacterSpacing(kernValue: -0.41)
            self.footerView.lockSwitch?.addTarget(self, action: #selector(toggleLockNotebookSwitch), for: .valueChanged)
            self.footerView.lockSwitch?.isOn = FTUserDefaults.isNotebookBackgroundLockEnabled()
        } else {
            self.footerView.isHidden = true
        }
    }

    @IBAction func toggleRequirePasswordSwitch(sender:Any?) {
        if self.passwordFlow == .setPassword {
            if let enableSwitch = self.headerView.enableSwitch, enableSwitch.isOn {
                self.tableView.resignFirstResponder()
                self.tableView.reloadInputViews()
                self.tableView.reloadData()
                self.configureFooterView(toShow: true)
            } else {
                self.configureFooterView(toShow: false)
                self.tableView.reloadData()
            }
        } else {
            self.handleEnablePwdOffForChangePasswordFlow()
        }
    }

    override func leftNavBtnTapped(_ sender: UIButton) {
        self.delegate?.cancelButtonAction()
    }
    
    override func rightNavBtnTapped(_ sender: UIButton) {
        self.tableView.endEditing(true)
        self.verifyUserInputs(passwordFlow: self.passwordFlow)
    }
}

extension FTPasswordViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.passwordFlow == .setPassword, let enableSwitch = self.headerView.enableSwitch, !enableSwitch.isOn {
            return 0
        }
        return self.passwordFlow.fieldCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let passwordCell = tableView.dequeueReusableCell(withIdentifier: "FTPassWordNormalCell", for: indexPath) as? FTPassWordNormalCell else {
            fatalError("Programmer error - Couldnot find FTPassWordNormalCell")
        }
        passwordCell.configureTextField()
        passwordCell.leftLabel.text = self.passwordFlow.fieldArray[indexPath.row]
        passwordCell.leftLabel.addCharacterSpacing(kernValue: -0.41)
        if indexPath.row == self.passwordFlow.fieldArray.count - 1 {
            passwordCell.textFeild.isSecureTextEntry = false
        }
        return passwordCell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    @IBAction func toggleLockNotebookSwitch() {
        var lockNotebook = FTUserDefaults.isNotebookBackgroundLockEnabled()
        if lockNotebook {
            lockNotebook = false
        } else {
            lockNotebook = true
        }
        FTUserDefaults.lockNotebookInBackground(lockNotebook)
        track("Shelf_Settings_Advanced_LockNB", params: ["toogle": lockNotebook ? "yes" : "no"], screenName: FTScreenNames.shelfSettings)
    }

}

extension FTPasswordViewController: UITextFieldDelegate {
    private func textFiledAssociatedTableViewCell(_ textField: UITextField) -> UITableViewCell? {
        var currentCell: UITableViewCell?;
        for eachCell in self.tableView.visibleCells {
            if let normCell = eachCell as? FTPassWordNormalCell
                , normCell.textFeild == textField
            {
                currentCell = normCell;
            }
        }
        return currentCell
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.returnKeyType == .done {
            self.verifyUserInputs(passwordFlow: self.passwordFlow)
            return false
        }
        if let cell = textFiledAssociatedTableViewCell(textField) {
            if let indexPath = self.tableView.indexPath(for: cell) {
                let nextIndexPath = getNextIndexPath(for: indexPath)
                if let nextView = getNextInputView(for: indexPath) {
                    if nextIndexPath.row == self.passwordFlow.fieldCount - 1 {
                        (nextView as? UITextField)?.returnKeyType = populateKeyBoardType()
                    }
                    else {
                        (nextView as? UITextField)?.returnKeyType = .next
                    }
                    nextView.becomeFirstResponder()
                    nextView.reloadInputViews()
                    return false
                }
            }
        }
        return true
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let isvalidate = validateFields()
        self.navigationItem.rightBarButtonItem?.isEnabled = isvalidate
        saveButton.alpha = isvalidate ? 1.0 : 0.5
        return true
    }

    func verifyUserInputs(passwordFlow: FTPasswordFlow) {
        func verifySetPasswordPolicy() -> PasswordPolicy {
            let setPassword = self.getRequiredFieldText(field: .setPassword)
            let confirmPassWord = self.getRequiredFieldText(field: .setVerifyPassword)
            let setHint = self.getRequiredFieldText(field: .setHint).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            if setPassword.isEmpty && confirmPassWord.isEmpty {
                return .empty
            }
            if setPassword == confirmPassWord {
                if setHint.isEmpty {
                    return .missingHint
                }
                return .success
            }
            return .failedToMatch
        }
        
        func verifyChangePasswordPolicy() -> PasswordPolicy {
            if (self.headerView.enableSwitch?.isOn ?? false) == false { //Collapsed mode
                let index1 =  IndexPath(row: 0, section: 0)
                let cell1 = self.tableView.cellForRow(at: index1) as? FTPassWordNormalCell
                if true == cell1?.textFeild.text?.isEmpty {
                    return .empty
                }
                return .success
            }
            else {
                if isEmpty() {
                    return .empty
                }
                else if false == matchNewPassword() {
                    return .failedToMatch
                }
                
                let changeHint = self.getRequiredFieldText(field: .changeHint)
                if changeHint.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                    return .missingHint
                }
                return .success
            }
        }
        
        let policy = passwordFlow == .setPassword ? verifySetPasswordPolicy() : verifyChangePasswordPolicy()
        if policy == .success {
            if self.passwordFlow == .setPassword {
                self.delegate?.didFinishVerification(onController: self)
            } else {
                let currentPwd = self.getRequiredFieldText(field: .currentPassword)
                self.delegate?.didFinishVerification(onController: self, currentPassword: currentPwd)
            }
        }
        else {
            policy.showErrorMessage(onController: self)
        }
    }

    func getNextIndexPath(for indexPath:IndexPath) -> IndexPath {
        if indexPath.row != self.passwordFlow.fieldCount - 1 {
            return IndexPath(row: indexPath.row+1, section: 0)
        }
        return IndexPath(row: 0, section: 0)
    }
    
    func getNextInputView(for indexPath:IndexPath) -> UIView? {
        let indexPath = getNextIndexPath(for: indexPath)
        if let cell = self.tableView.cellForRow(at: indexPath) as? FTPassWordNormalCell {
            return cell.textFeild
        }
        return nil
    }

    func populateKeyBoardType() -> UIReturnKeyType {
        if passwordFlow == .setPassword {
            let index1:IndexPath = IndexPath(row: 0, section: 0)
            let index2:IndexPath = IndexPath(row: 1, section: 0)
            guard let rowPassword = self.tableView.cellForRow(at: index1) as? FTPassWordNormalCell,
               let rowConfirmPassword = self.tableView.cellForRow(at: index2) as? FTPassWordNormalCell else {
                   return .done
               }
            
               if (rowPassword.textFeild.text!.isEmpty == false) && (rowConfirmPassword.textFeild.text!.isEmpty == false) {
                    return .done
               }
            return .next
        } else {
            let index1:IndexPath = IndexPath(row: 0, section: 0)
            let index2:IndexPath = IndexPath(row: 1, section: 0)
            let index3:IndexPath = IndexPath(row: 2, section: 0)
            guard let rowPassword = self.tableView.cellForRow(at: index1) as? FTPassWordNormalCell,  let rowNewPassword =  self.tableView.cellForRow(at: index2) as? FTPassWordNormalCell, let rowConfirmPassword = self.tableView.cellForRow(at: index3) as? FTPassWordNormalCell else {
                return .done
            }
            
            if (rowPassword.textFeild.text!.isEmpty == false) && (rowNewPassword.textFeild.text!.isEmpty == false) && (rowConfirmPassword.textFeild.text!.isEmpty == false) {
                return .done
            }
            return .next
        }
    }
}

// Exclusive for Change password
extension FTPasswordViewController {
    
    @objc private func toggleIsTouchIDEnabled() {
        self.isTouchIDEnabledManually = !self.isTouchIDEnabledManually
    }

    func isEmpty() -> Bool {
        let index1 =  IndexPath(row: 0, section: 0)
        let index2 =  IndexPath(row: 1, section: 0)

        let cell1 = self.tableView.cellForRow(at: index1) as? FTPassWordNormalCell
        let cell2 = self.tableView.cellForRow(at: index2) as? FTPassWordNormalCell
        
        if self.isTouchIDEnabledManually != self.isTouchIDEnabledAtPresent && false == cell1?.textFeild.text?.isEmpty {
            return false
        }
        else if false == cell1?.textFeild.text?.isEmpty && false == cell2?.textFeild.text?.isEmpty {
            return false
        }
        return true
    }
    
    func matchNewPassword() -> Bool {
        let index2 =  IndexPath(row: 1, section: 0)
        let index3 =  IndexPath(row: 2, section: 0)
        let cell2 = self.tableView.cellForRow(at: index2) as? FTPassWordNormalCell
        let cell3 = self.tableView.cellForRow(at: index3) as? FTPassWordNormalCell

        if self.isTouchIDEnabledManually != self.isTouchIDEnabledAtPresent {
            let cell2Text = cell2?.textFeild.text
            if cell2Text == cell3?.textFeild.text {
                if((cell2Text != nil) && (!cell2Text!.isEmpty)) {
                    self.newPassword = cell2!.textFeild.text
                }
                return true
            }
            return false
        }
        else if cell2?.textFeild.text == cell3?.textFeild.text {
            self.newPassword = cell2!.textFeild.text
            return true
        }
        return false
    }
    
    @objc func didSucceedAuthentication() {
    }
    
    @objc func didFailedToAuthentication(notification:Notification?) {
        if self.passwordFlow == .changePassword {
            self.toDisablePassword = false
            self.headerView.enableSwitch?.setOn(true, animated: true)
        }
        var message:String? = "PleaseEnterValidPassword".localized

        attemptsCounter += 1
        if attemptsCounter == 3 {
            attemptsCounter = 0
            //show hint
            message = nil
            
            if let error = notification?.object as? NSError {
                if let hint = error.userInfo["hint"] as? String, false == hint.isEmpty {
                    message = "Hint: " + hint
                }
            }
        }
        let alert = UIAlertController(title: "IncorrectPassword".localized, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: {_ in
            if self.passwordFlow == .changePassword {
                self.handleEnablePwdOffForChangePasswordFlow()
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }

    private func handleEnablePwdOffForChangePasswordFlow() {
        let alertController = UIAlertController.init(title: "EnterPassword".localized, message: "", preferredStyle: .alert)
        weak var weakAlertController = alertController
        let okAction = UIAlertAction.init(title: "OK".localized, style: .default, handler: { _ in
            let text = weakAlertController?.textFields?.first?.text
            guard let pin = text, !pin.isEmpty else {
                // when password is empty
                self.headerView.enableSwitch?.setOn(true, animated: true)
                PasswordPolicy.empty.showErrorMessage(onController: self)
                return
            }
            self.toDisablePassword = true
            self.delegate?.didFinishVerification(onController: self, currentPassword: pin)
        })
        alertController.addAction(okAction)
        let cancelAction = UIAlertAction.init(title: "Cancel".localized,
                                              style: .cancel,
                                              handler: {_ in
            self.toDisablePassword = false
            self.headerView.enableSwitch?.setOn(true, animated: true)
        })
        alertController.addAction(cancelAction)
        
        alertController.addTextField(configurationHandler: {[weak self] (textFiled) in
            textFiled.delegate = self
            textFiled.isSecureTextEntry = true
            textFiled.setDefaultStyle(.defaultStyle)
            textFiled.setStyledPlaceHolder("Password".localized, style: .defaultStyle)
        })
        self.present(alertController, animated: true, completion: nil)
    }
}

class FTPasswordKeypadController: UIViewController {
    func registerForKeyboardDidShowNotification(scrollView: UIScrollView, usingBlock block: ((CGSize?) -> Void)? = nil) {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: nil, using: { [weak scrollView] (notification) -> Void in
            if let inScrollView = scrollView {
                let userInfo = notification.userInfo!
                let keyboardSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue.size
                let contentInsets = UIEdgeInsets(top: inScrollView.contentInset.top, left: inScrollView.contentInset.left, bottom: keyboardSize.height, right: inScrollView.contentInset.right)
                inScrollView.contentInset = contentInsets
                inScrollView.scrollIndicatorInsets = contentInsets
                block?(keyboardSize)
            }
        });
    }
    
    func registerForKeyboardWillHideNotification(scrollView: UIScrollView, usingBlock block: (() -> Void)? = nil) {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil, using: { [weak scrollView] (notification) -> Void in
            if let inScrollView = scrollView {
                let contentInsets = UIEdgeInsets(top: inScrollView.contentInset.top, left: inScrollView.contentInset.left, bottom: 0, right: inScrollView.contentInset.right)
                inScrollView.contentInset = contentInsets
                inScrollView.scrollIndicatorInsets = contentInsets
                block?()
            }
        })
    }
}
