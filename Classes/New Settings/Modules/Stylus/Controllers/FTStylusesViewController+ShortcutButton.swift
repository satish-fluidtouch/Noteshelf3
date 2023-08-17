//
//  FTStylusesViewController+ShortcutButton.swift
//  Noteshelf
//
//  Created by Siva on 16/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//


import Foundation

extension FTStylusesViewController: FTStylusChooseActionDelegate {
//
//    // MARK: - Segue
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if let cell = sender as? FTStylusShortcutButtonTableViewCell, segue.destination is FTStylusChooseActionViewController {
//            let indexPath = self.tableView?.indexPath(for: cell)!
//            self.selectedActionIndexPath = indexPath
//
//            if let accessoryButtonActionPicker = segue.destination as? FTStylusChooseActionViewController {
//                accessoryButtonActionPicker.delegate = self
//                accessoryButtonActionPicker.tag = (indexPath?.row)!
//                accessoryButtonActionPicker.currentSelection = self.accessoryButtonAction(forIndexPath: indexPath!)
//
//                track("settings_stylus", params: ["buttonAction": "\(accessoryButtonActionPicker.tag) - \(self.currentStylus.stylusType)"])
//            }
//        }
//    }

    // MARK: - Custom
    func actionButtonTitle(forIndexPath indexPath: IndexPath) -> String {
        var stringTitle = ""
        if self.currentStylus.supportsDoubleTap {
            if indexPath.row % 2 == 0 {
                let index = (indexPath.row + 2) / 2;
                if(index == 1) {
                    stringTitle = NSLocalizedString("ButtonOnePress", comment: "Button 1 Press");
                } else {
                    stringTitle = NSLocalizedString("ButtonTwoPress", comment: "Button 2 Press");
                }
            } else {
                let index = (indexPath.row + 1) / 2;
                let format = NSLocalizedString("StylusButtonDoupleTapAction", comment: "Button %d Douple Tap");
                stringTitle = String(format: format, index);
            }
        } else {
            if(indexPath.row == 0) {
                stringTitle = NSLocalizedString("ButtonOnePress", comment: "Button 1 Press");
            } else {
                stringTitle = NSLocalizedString("ButtonTwoPress", comment: "Button 2 Press");
            }
        }
        return stringTitle
    }

    func accessoryButtonActionIndex(forIndexPath indexPath: IndexPath) -> RKAccessoryButtonAction {
        var buttonIndex = 0;
        var action = kAccessoryButtonActionNone;

        if self.currentStylus.supportsDoubleTap {
            if indexPath.row % 2 == 0 {
                buttonIndex = (indexPath.row + 2) / 2;
                action = self.currentStylus.buttonPressAction(buttonIndex);
            } else {
                buttonIndex = (indexPath.row + 1) / 2;
                action = self.currentStylus.buttonDoubleTapAction(buttonIndex);
            }
        } else {
            buttonIndex = indexPath.row + 1;
            action = self.currentStylus.buttonPressAction(buttonIndex);
        }
        return action;
    }

    func accessoryButtonAction(forIndexPath indexPath: IndexPath) -> RKAccessoryButtonAction {
        let index = self.accessoryButtonActionIndex(forIndexPath: indexPath)
        return index
    }

    // MARK: - AccessoryButtonActionPickerDelegate
    func chooseActionPicker(_ picker: FTStylusChooseActionViewController?, valueChanged newValue: RKAccessoryButtonAction) {
        let indexPath = self.selectedActionIndexPath

        if self.currentStylus.supportsDoubleTap {
            if (indexPath?.row)! % 2 == 0 {
                let buttonIndex = ((indexPath?.row)! + 2) / 2;
                self.currentStylus.setButtonPressAction(buttonIndex, action: newValue);
            } else {
                let buttonIndex = ((indexPath?.row)! + 1) / 2;
                self.currentStylus.setButtonDoubleTapAction(buttonIndex, action: newValue);
            }
        } else {
            let buttonIndex = (indexPath?.row)! + 1;
            self.currentStylus.setButtonPressAction(buttonIndex, action: newValue);
        }

        self.tableView?.reloadData();
    }
}
