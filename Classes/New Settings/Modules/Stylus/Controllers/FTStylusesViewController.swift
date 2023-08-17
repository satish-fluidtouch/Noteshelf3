//
//  FTStylusesViewController.swift
//  Noteshelf
//
//  Created by Siva on 14/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTStylusesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView?

    var styluses: [FTStylusPenSettingsProtocol] = []
    var contentSize = CGSize.zero
    var hideNavButtons = false
    var currentStylus: FTStylusPenSettingsProtocol! {
        didSet {
            if(oldValue == nil || oldValue.stylusType != self.currentStylus.stylusType) {
                self.showConnectOption = false;
                self.currentStylus.setSelected();

                if self.currentStylus.isEnabled {
                    if self.currentStylus.connectionStyle == .spinnerPair
                        && !self.currentStylus.isDisabled {
                        self.styluses.forEach({ stylus in
                            var stylusModel = stylus;
                            if(stylusModel.stylusType != self.currentStylus.stylusType) {
                                stylusModel.isEnabled = false;
                            }
                        })
                        #if !targetEnvironment(macCatalyst)
                        SharedPressurePenEngine?.updateDefaults();
                        self.currentStylus.isEnabled = true;
                        PressurePenEngine.shared().refresh();
                        #endif
                    }
                    self.currentStylus.prepare()
                }
                if(oldValue != nil) {
                    let connectedStr = self.currentStylus.isConnected ? "Yes" : "No";
                    track("settings_stylus", params: ["action" : "setCurrentStylus", "stylusType": self.currentStylus.stylusType, "Connected": connectedStr])
                }
            }
        }
    }
    var isConnectingStylus = false
    var isDisconnected = true
    var selectedActionIndexPath: IndexPath!
    var showConnectOption = false;


    // MARK: - UIViewController
    override func viewDidLoad() {

        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: FTPencilActionChangedNotification), object: nil, queue: nil) { [weak self] _ in
            self?.tableView?.reloadData()
        }
        
        if isDeviceSupportsApplePencil() {
            self.styluses = [FTStylusPenApplePencil()]
            self.currentStylus = self.styluses[0]
        }

        self.reloadOptions()
        self.registerStylusStatusNotifications()

        super.viewDidLoad()
        self.tableView?.alwaysBounceVertical = true
        self.tableView?.dataSource = self
        self.tableView?.delegate = self
        var frame = CGRect.zero
#if targetEnvironment(macCatalyst)
        frame.size.height = FTGlobalSettingsController.macCatalystTopInset;
#else
        frame.size.height = .leastNormalMagnitude
#endif
        self.tableView?.tableHeaderView = UIView(frame: frame)
        self.tableView?.separatorColor = UIColor.appColor(.black10)
        self.tableView?.estimatedRowHeight = UITableView.automaticDimension
        if self.hideNavButtons {
            self.view.backgroundColor = UIColor.appColor(.popoverBgColor)
            self.configureCustomNavigation(title: FTNewSettingsOptions.applePencil.rawValue.localized)
        } else {
            self.view.backgroundColor = UIColor.appColor(.formSheetBgColor)
            self.configureNewNavigationBar(hideDoneButton: false, title:  FTNewSettingsOptions.applePencil.rawValue.localized)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.contentSize != .zero {
            self.navigationController?.preferredContentSize = contentSize
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc override func rightNavBtnTapped(_ sender : UIButton) {
        self.dismiss(animated: true)
    }
    // MARK: - PressureSensitivity
    @IBAction func togglePressureSensitivity(_ sender: UISwitch) {
        self.currentStylus.isPressureSentiveEnabled = sender.isOn;
        let connectedStr = self.currentStylus.isPressureSentiveEnabled ? "Yes" : "No";
        track("Shelf_Settings_Stylus_PressureSens", params: ["toogle":connectedStr], screenName: FTScreenNames.shelfSettings)
    }

    // MARK: - Apple Pencil
    @IBAction func toggleSwitchToPair(_ sender: UISwitch) {
        self.showConnectOption = false;
        self.styluses.forEach({ stylus in
            var stylusModel = stylus;
            stylusModel.isEnabled = false
        })
        self.currentStylus.isEnabled = sender.isOn;
        self.currentStylus.isEnabled ? self.stylusDidConnect() : self.stylusDidDisconnect()
        #if !targetEnvironment(macCatalyst)
        SharedPressurePenEngine?.refresh()
        #endif
    }

    //MARK:- UITableView Delegate / Datesource
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return self.currentStylus.isConnected ?  3 : 1
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)
        if cell is FTStylusDoubleTapTableViewCell {
            let storyboard = UIStoryboard(name: "FTSettings_Stylus", bundle: nil)
            if let controller = storyboard.instantiateViewController(withIdentifier: "FTApplePencilDoubleTapViewController") as? FTApplePencilDoubleTapViewController {
                controller.hideNavButtons = self.hideNavButtons
                if contentSize != .zero {
                    controller.contentSize = CGSize(width: defaultPopoverWidth, height: 340)
                }
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
   
     func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
         if indexPath.section == 0 && indexPath.row == 2 {
             return  UITableView.automaticDimension
         }
         return FTSettingsConstants.rowHeight
    }
    
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        //ToShowEnable/DisableSwitch
        if self.currentStylus.connectionStyle != .toggleToPair
            && indexPath.section == 0
            && indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: FTStylusToggleToPairTableViewCell.reusableIdentifier(), for: indexPath) as? FTStylusToggleToPairTableViewCell else {
                fatalError("Programmer error - Couldnot find FTStylusToggleToPairTableViewCell")
            }
            cell.updateEnableText(stylus: self.currentStylus)
            cell.switchActive.isOn = self.currentStylus.isEnabled
            return cell
        }
        
        //AfterEnable/DisableSwitchForAllStyluses
        if self.currentStylus.connectionStyle == .toggleToPair {
            if indexPath.row == 0
                && indexPath.section == 0 {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: FTStylusToggleToPairTableViewCell.reusableIdentifier(), for: indexPath) as? FTStylusToggleToPairTableViewCell else {
                    fatalError("Programmer error- couldnot find FTStylusToggleToPairTableViewCell")
                }
                cell.updateEnableText(stylus: self.currentStylus)
                cell.switchActive.isOn = self.currentStylus.isEnabled
                return cell
            } else if self.currentStylus.isConnected {
                if indexPath.row == 1 {
                    return self.pressureSensitivityCell(forIndexPath: indexPath)
                } else if indexPath.row == RowNumber_ApplePencilDoubleTap {
                    return self.applePencilDoubleTapCell(forIndexPath: indexPath)
                }
            }
        }
        
        if self.currentStylus.isConnected {
            switch indexPath.section {
            case SectionNumber_StatusSection_Connected:
                if indexPath.row == RowNumber_PressureSensitivityCell_Connected {
                    return self.pressureSensitivityCell(forIndexPath: indexPath)
                } else if indexPath.row == RowNumber_ApplePencilDoubleTap {
                    return self.applePencilDoubleTapCell(forIndexPath: indexPath)
                }

            case SectionNumber_PressDetectionSection_Connected:
                return self.currentStylus.pressDetectionCell(tableView, forIndexPath: indexPath)

            default:
                break
            }
            
        } else {
            if self.showConnectOption {
                    return self.connectCell(forIndexPath: indexPath);
            } else {
                if  self.currentStylus.isEnabled {
                    return self.pairingCell(forIndexPath: indexPath)
                }
            }
        }
         return self.pairingCell(forIndexPath: indexPath)
    }
}
