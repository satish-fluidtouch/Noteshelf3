//
//  FTBaseStylusPen.swift
//  Noteshelf
//
//  Created by Siva on 16/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

let BatteryImageSize = CGSize(width: 26, height: 12)

enum FTStylusConnectionStyle {
    case touchToPair
    case spinnerPair
    case toggleToPair
}

protocol FTStylusDeprecatedSupport {
    var deprecateLocalizedString : String {get};
}

protocol FTStylusPenSettingsProtocol {
    var stylusName: String { get };
    var stylusType: String { get };
    var stylusIcon: UIImage { get };

    var supportsPressureSensitivity: Bool { get };
    var supportsDoubleTap: Bool { get };
    var supportsBatteryLevel: Bool { get };
    var isDisabled: Bool { get };
    var connectedMessage: String { get };
    var errorMessage: String { get };

    var connectionStyle: FTStylusConnectionStyle { get };

    var isPressureSentiveEnabled: Bool { get  set };
    var isEnabled: Bool { get set };

    var isSelected: Bool { get };

    var isConnected: Bool { get };

    var needsConnectPage: Bool { get };

    func prepare()

    func unload()

    func helpURL() -> URL;

    func numberOfButtons() -> Int;

    func buttonPressAction(_ index: Int) -> RKAccessoryButtonAction;
    func setButtonPressAction(_ index: Int, action: RKAccessoryButtonAction);

    func buttonDoubleTapAction(_ index: Int) -> RKAccessoryButtonAction;
    func setButtonDoubleTapAction(_ index: Int, action: RKAccessoryButtonAction);

    func batteryImage(aboveView superview: UIView) -> UIImage?;


    //Applicable only for SpinnerToPair
    func pairingCell(_ tableView: UITableView, forIndexPath indexPath: IndexPath, withConnectingStatus isConnecting: Bool) -> UITableViewCell;

    //Applicable only for 53Pencil
    var supportsPressTest: Bool { get };
    func pressDetectionCell(_ tableView: UITableView, forIndexPath indexPath: IndexPath) -> UITableViewCell;

    func setSelected();
}

extension FTStylusPenSettingsProtocol {
    var supportsBatteryLevel: Bool {
        get {
            return true;
        }
    }

    var supportsDoubleTap: Bool {
        get {
            return false;
        }
    }

    var needsConnectPage: Bool {
        get {
            return (self.connectionStyle == .spinnerPair);
        }
    }

    var isSelected: Bool {
        get {
            if let selectedStylusType = UserDefaults.standard.value(forKey: SELECTED_STYLUS) as? String, selectedStylusType == self.stylusType {
                return true;
            }
            return false;
        }
    }

    var connectedMessage: String {
        get {
            return "\(self.stylusName)\n\(NSLocalizedString("Connected", comment: "Connected"))";
        }
    }

    func setSelected() {
        let userDefaults = UserDefaults.standard;
        userDefaults.setValue(self.stylusType, forKey: SELECTED_STYLUS);
        userDefaults.synchronize();
    }

    func batteryImage(aboveView superview: UIView) -> UIImage? {
        let imageFolder = "UniversalSettings/Stylus/BatteryLevel/";
        return UIImage(named: "\(imageFolder)1");
    }


    //Applicable only for SpinnerToPair
    func pairingCell(_ tableView: UITableView, forIndexPath indexPath: IndexPath, withConnectingStatus isConnecting: Bool) -> UITableViewCell {
        return UITableViewCell()
    }

    //Applicable only for 53Pencil
    var supportsPressTest: Bool {
        get {
            return false;
        }
    }
}
