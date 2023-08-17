//
//  FTStylusPenApplePencil.swift
//  Noteshelf
//
//  Created by Siva on 16/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTStylusPenApplePencil: NSObject, FTStylusPenSettingsProtocol {
    func pressDetectionCell(_ tableView: UITableView, forIndexPath indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }

    // MARK: - FTStylusPenSettingsProtocol properties
    var stylusName: String {
        var deviceName: String? = nil;
        deviceName = "Apple Pencil";
        return deviceName!;
    }

    var stylusType: String {
        return "Apple Pencil";
    }

    var stylusIcon: UIImage {
    return UIImage(named: "UniversalSettings/Stylus/apple_pencil2")!;
    }

    var supportsPressureSensitivity: Bool {
        return true;
    }

    var supportsBatteryLevel: Bool {
        return false;
    }

    var isDisabled: Bool {
        return false;
    }

    var errorMessage: String {
        return "";
    }

    var connectionStyle: FTStylusConnectionStyle {
        return FTStylusConnectionStyle.toggleToPair;
    }

    var isPressureSentiveEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: PressureSensitivity_Key);
        }
        set {
            UserDefaults.standard.set(newValue, forKey: (PressureSensitivity_Key));
            UserDefaults.standard.synchronize();
        }
    }

    var isEnabled: Bool {
        get {
            return UserDefaults.isApplePencilEnabled();
        }
        set {
            #if !targetEnvironment(macCatalyst)
            SharedPressurePenEngine?.enableStylus(withIdentifier: APPLE_PENCIL_ENABLED, status: newValue)
            #endif
        }
    }

    var isConnected: Bool {
        return self.isEnabled;
    }

    // MARK: - FTStylusPenSettingsProtocol methods
    func prepare() {
    }

    func unload() {
    }

    func helpURL() -> URL {
        return URL(string: "https://support.apple.com/en-us/HT205236")!;
    }

    func numberOfButtons() -> Int {
        return 0;
    }

    func buttonPressAction(_ index: Int) -> RKAccessoryButtonAction {
        let key = String(format: "APPLE_PENCIL_SETTINGS_BUTTON_%d_PRESS", index);
        return  RKAccessoryButtonAction(UserDefaults.standard.integer(forKey: key));
    }

    func setButtonPressAction(_ index: Int, action: RKAccessoryButtonAction) {
        let key = String(format: "APPLE_PENCIL_SETTINGS_BUTTON_%d_PRESS", index);
        UserDefaults.standard.set(action.rawValue, forKey: key);
    }

    func buttonDoubleTapAction(_ index: Int) -> RKAccessoryButtonAction {
        let key = String(format: "APPLE_PENCIL_SETTINGS_BUTTON_%d_DOUBLE_TAP", index);
        return  RKAccessoryButtonAction(UserDefaults.standard.integer(forKey: key));
    }

    func setButtonDoubleTapAction(_ index: Int, action: RKAccessoryButtonAction) {
        let key = String(format: "APPLE_PENCIL_SETTINGS_BUTTON_%d_DOUBLE_TAP", index);
        UserDefaults.standard.set(action.rawValue, forKey: key);
    }
}
