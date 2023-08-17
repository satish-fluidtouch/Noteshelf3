//
//  FTShowPageDateTableViewCell.swift
//  Noteshelf
//
//  Created by Siva on 28/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//


import UIKit

class FTShowPageDateTableViewCell: FTSettingsBaseTableViewCell {

    @IBOutlet weak var switchShowDate: UISwitch!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.layer.cornerRadius = 8
        self.switchShowDate.isOn = UserDefaults.standard.bool(forKey: "Shelf_ShowDate");
        self.accessibilityValue = self.switchShowDate.isOn ? "ON" : "OFF";
        NotificationCenter.default.addObserver(self, selector: #selector(self.showDateToggled), name: NSNotification.Name(FTShelfShowDateChangeNotification), object: nil);
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    // MARK: - Additional methods
    @IBAction func toggleDatePageNumber(_ sender: AnyObject) {
        UserDefaults.standard.set(self.switchShowDate.isOn, forKey: "Shelf_ShowDate");
        UserDefaults.standard.synchronize();
        NotificationCenter.default.post(name: Notification.Name(rawValue: FTShelfShowDateChangeNotification), object: nil);
        let enabledStr = (self.switchShowDate.isOn) ? "Yes" : "No";
        track("Shelf_Settings_ShowDateonShelf", params: ["toogle":enabledStr], screenName: FTScreenNames.shelfSettings)
        self.accessibilityValue = self.switchShowDate.isOn ? "ON" : "OFF";
    }
    @objc func showDateToggled() {
        self.switchShowDate.isOn = UserDefaults.standard.bool(forKey: "Shelf_ShowDate")
    }
}
