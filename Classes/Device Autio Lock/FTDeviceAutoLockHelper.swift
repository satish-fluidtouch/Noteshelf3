//
//  FTDeviceAutoLockHelper.swift
//  Noteshelf
//
//  Created by Amar on 25/05/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTDeviceAutoLockHelper: NSObject {
    static let share: FTDeviceAutoLockHelper = FTDeviceAutoLockHelper();

    private var scenes: Set<String> = Set<String>();
    func notebookWillConnectScene(_ sceneID: String) {
        self.scenes.insert(sceneID);
        self.updateDeviceAutoLock();
    }

    func notebookDidDisconnectScene(_ sceneID: String) {
        self.scenes.remove(sceneID);
        self.updateDeviceAutoLock();
    }

    func notebookWillEnterForeground(_ sceneID: String) {
        self.scenes.insert(sceneID);
        self.updateDeviceAutoLock();
    }
    
    func notebookDidEnterBackground(_ sceneID: String) {
        self.scenes.remove(sceneID);
        self.updateDeviceAutoLock();
    }

    private func updateDeviceAutoLock() {
        if self.scenes.isEmpty {
            UIApplication.shared.isIdleTimerDisabled = false;
        }
        else if FTUserDefaults.disableAutoLock {
            UIApplication.shared.isIdleTimerDisabled = true;
        }
    }
    func autoLockUsingDisableAutoLockStatus(){
        if FTUserDefaults.disableAutoLock {
            UIApplication.shared.isIdleTimerDisabled = true;
        }
        else {
            UIApplication.shared.isIdleTimerDisabled = false;
        }
    }
}
