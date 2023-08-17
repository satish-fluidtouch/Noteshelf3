//
//  FTStylusesViewController+StylusOptionsList.swift
//  Noteshelf
//
//  Created by Siva on 15/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

let RowNumber_ApplePencilDoubleTap = 2

let RowNumber_ConnectedCell_Connected = 1
let RowNumber_PressureSensitivityCell_Connected = 2
let SectionNumber_StatusSection_Connected = 0

let SectionNumber_PressDetectionSection_Connected = 2


extension FTStylusesViewController {
    // MARK: - Cells
    func connectCell(forIndexPath indexPath: IndexPath) -> FTSettingsBaseTableViewCell {
        let cell = self.basicCell(forIndexPath: indexPath);
        cell.labelTitle!.text = NSLocalizedString("Connect", comment: "Connect");
        return cell
    }

   func pairingCell(forIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView?.dequeueReusableCell(withIdentifier: FTStylusToggleToPairTableViewCell.reusableIdentifier(), for: indexPath) as? FTStylusToggleToPairTableViewCell
        cell?.switchActive.isOn = self.currentStylus.isEnabled
        return cell!
    }

    func pressureSensitivityCell(forIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView?.dequeueReusableCell(withIdentifier: FTStylusPressureSensitivityTableViewCell.reusableIdentifier(), for: indexPath) as? FTStylusPressureSensitivityTableViewCell
        cell?.switchPressureSensitivity.isOn = self.currentStylus.isPressureSentiveEnabled;
        return cell!
    }

    func disconnectCell(forIndexPath indexPath: IndexPath) -> FTSettingsBaseTableViewCell {
        let cell = self.basicCell(forIndexPath: indexPath);
        cell.labelTitle!.text = NSLocalizedString("Disconnect", comment: "Disconnect");
        return cell
    }

    func applePencilDoubleTapCell(forIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView?.dequeueReusableCell(withIdentifier: "FTStylusDoubleTapTableViewCell", for: indexPath) as? FTStylusDoubleTapTableViewCell
        let actionType = FTUserDefaults.applePencilDoubleTapAction()
        cell?.titleLablel.text = NSLocalizedString("DoubleTapAction", comment: "Double-Tap Action")
        if actionType == .systemDefault {
            cell?.detailTextLablel?.text = NSLocalizedString("SystemDefaultsDescription", comment: "System default ") + ": \(applePencilMessageDefaultOption())"
        } else {
            let actionString = FTUserDefaults.applePencilDoubleTapAction().localizedString()
            cell?.detailTextLablel?.text = actionString
        }
        return cell!
    }

    func applePencilMessageDefaultOption() -> String {
        switch UIPencilInteraction.preferredTapAction {
        case .switchEraser:
            return NSLocalizedString("OptionEraser", comment: "Eraser")
        case .switchPrevious:
            return NSLocalizedString("OptionLastUsedTool", comment: "Previous Tool")
        case .showColorPalette:
            return NSLocalizedString("OptionColorPalette", comment: "Show Colors")
        default:
            return NSLocalizedString("BackupOff", comment: "Off")
        }
}

    // MARK: - PrototypeCells
    func basicCell(forIndexPath indexPath: IndexPath) -> FTSettingsBaseTableViewCell {
        let cell = self.tableView?.dequeueReusableCell(withIdentifier: "CellBasic", for: indexPath) as? FTSettingsBaseTableViewCell

        return cell!
    }


    //Reload data
    func reloadOptions() {
        self.tableView?.reloadData()
    }

}
