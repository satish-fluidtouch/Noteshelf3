//
//  FTPasswordViewModel.swift
//  Noteshelf3
//
//  Created by Narayana on 05/05/22.
//

import Foundation
import FTNewNotebook
import SwiftUI

class FTPasswordViewModel: NSObject, ObservableObject {
    let passwordTitle = NSLocalizedString("password.title", comment: "PASSWORD")
    let passwordInfo = NSLocalizedString("password.info", comment: "Info")
    let passwordPlaceHolder = NSLocalizedString("password.placeholder", comment: "required")
    let passwordText = NSLocalizedString("newnotebook.password", comment: "Password")
    let confirmPasswordText = NSLocalizedString("password.confirmpassword", comment: "Confirm Password")
    let hintText = NSLocalizedString("password.hint", comment: "Hint")
    let useFaceId = NSLocalizedString("password.usefaceid", comment: "Use Face ID")
    let useTouchId = NSLocalizedString("password.usetouchid", comment: "Use Touch ID")
    let lockNotebooksInBgLocalisedText = NSLocalizedString("password.locknotebooks", comment: "Lock Notebooks in Background")
    let cancel = NSLocalizedString("cancel", comment: "cancel")
    let save = NSLocalizedString("save", comment: "save")
    let enablePassword = NSLocalizedString("password.enablePassword", comment: "Enable Password")
    let currentPasswordText = NSLocalizedString("password.currentPassword", comment: "Current Password")
    let newPasswordText = NSLocalizedString("password.newPassword", comment: "New Password")
    let _passwordInfo = NSLocalizedString("notebookSettings.password.info", comment: "Info")
    let changePasswordText = NSLocalizedString("password.changePassword", comment: "Change Password")

    var toShowBiometricOption: Bool {
        let toShow = FTBiometricManager.shared().isTouchIDEnabled()
        return toShow
    }

    var biometricText: String {
        var text = useFaceId
        if FTBiometricManager.shared().biometryType == FTBiometryTypeTouchID {
            text = useTouchId
        }
        return text
    }
    var passwordDetails: FTPasswordModel?

    @Published var lockNotebooksInBg: Bool = FTUserDefaults.isNotebookBackgroundLockEnabled() {
        didSet {
            lockNotebooksInBackground()
        }
    }
    private func lockNotebooksInBackground(){
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
