//
//  FTStylusesViewController+PressureEngineDelegate.swift
//  Noteshelf
//
//  Created by Siva on 15/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//


import Foundation

extension FTStylusesViewController {
    func registerStylusStatusNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.stylusWillConnect), name: NSNotification.Name(rawValue: FTSettingsConstants.NotificationKey_StylusWillConnect), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.stylusDidConnect), name: NSNotification.Name(rawValue: FTSettingsConstants.NotificationKey_StylusDidConnect), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.stylusDidDisconnect), name: NSNotification.Name(rawValue: FTSettingsConstants.NotificationKey_StylusDidDisconnect), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(self.stylusDidBatteryLevelChange), name: NSNotification.Name(rawValue: FTSettingsConstants.NotificationKey_StylusDidBatteryLevelChange), object: nil)
    }

    @objc func stylusWillConnect() {
        self.isConnectingStylus = true
        self.isDisconnected = false
        self.reloadOptions()
    }

    @objc func stylusDidConnect() {
        self.isConnectingStylus = false
        self.isDisconnected = false
        if self.currentStylus.connectionStyle == .touchToPair {
//            self.currentStylus.isEnabled = true
            #if !targetEnvironment(macCatalyst)
            SharedPressurePenEngine?.updateDefaults();
            #endif
        }
        self.reloadOptions()

//        self.updateStylusSettingsButton();
    }

    @objc func stylusDidDisconnect() {
        self.isConnectingStylus = false
        self.isDisconnected = true
        self.currentStylus.unload()
        self.reloadOptions()

//        self.updateStylusSettingsButton();
    }

    @objc func stylusDidBatteryLevelChange() {
        self.reloadOptions()
    }

    //Actions
    func connectStylus() {
        self.reloadOptions();
        #if !targetEnvironment(macCatalyst)
        SharedPressurePenEngine?.refresh()
        #endif
    }

    func disconnectStylus() {
        for eachStylus in self.styluses {
            var stylusModel = eachStylus;
            stylusModel.isEnabled = false;
        }
        if self.currentStylus.needsConnectPage {
            self.showConnectOption = true;
        }
        DispatchQueue.main.async {
            #if !targetEnvironment(macCatalyst)
            SharedPressurePenEngine?.refresh()
            #endif
            self.currentStylus.isEnabled = true;
        }
        track("settings_stylus", params: ["action" : "disconnected", "stylusType": self.currentStylus.stylusType])
    }

    func openHelpPage() {
        UIApplication.shared.open(self.currentStylus.helpURL() as URL, options: [:], completionHandler: nil);
        let isConnected = self.currentStylus.isConnected ? "Yes" : "No";
        track("settings_stylus", params: ["action" : "help", "stylusType": self.currentStylus.stylusType, "Connected": isConnected])
    }
}
