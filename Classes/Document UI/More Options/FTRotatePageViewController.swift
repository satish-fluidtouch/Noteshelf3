//
//  FTRotatePageViewController.swift
//  Noteshelf
//
//  Created by Akshay on 04/05/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum FTPageRotation: UInt, CaseIterable {
    case nintetyClockwise = 90
    case nintetyCounterClockwise = 270
    case oneEighty = 180

    var localizedTitle: String {
        switch self {
        case .nintetyClockwise:
            return NSLocalizedString("nintetyClockwise", comment: "Clockwise 90°")
        case .nintetyCounterClockwise:
            return NSLocalizedString("nintetyCounterClockwise", comment: "Counter Clockwise 90°")
        case .oneEighty:
            return NSLocalizedString("oneEighty", comment: "Clockwise 180°")
        }
    }
}


class FTRotatePageViewController: UIViewController {

    @IBOutlet weak var tblSettings: UITableView!

    var rotationAngleChanged: ((_ angle: UInt) -> Void)?

    private var settings = [FTNotebookOptionRotationAngle]()
    override func viewDidLoad() {
        super.viewDidLoad()
        for item in FTPageRotation.allCases {
            let setting = FTNotebookOptionRotationAngle(rotation: item)
            settings.append(setting)
        }
        tblSettings.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.configureCustomNavigation(title: "Rotate Page".localized)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.preferredContentSize = CGSize(width: defaultPopoverWidth, height: 170)
    }
}

extension FTRotatePageViewController : UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {        
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FTNotebookMoreOptionsCell", for: indexPath)
        if let settingCell = cell as? FTNotebookMoreOptionsCell {
            settingCell.configure(with: settings[indexPath.row])
            settingCell.backgroundColor = UIColor.appColor(.cellBackgroundColor)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? CGFloat.leastNonzeroMagnitude : 16.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeight = section == 0 ? CGFloat.leastNonzeroMagnitude : 16.0
        let sectionHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: sectionHeight))
        sectionHeaderView.backgroundColor = .clear
        return sectionHeaderView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let angle = self.settings[indexPath.row].rotation.rawValue
        self.rotationAngleChanged?(angle)
        
        var paramValue: String = ""
        let setting = self.settings[indexPath.row]
        switch self.settings[indexPath.row].rotation {
        case .nintetyClockwise:
            paramValue = "Clockwise90"
        case .nintetyCounterClockwise:
            paramValue = "AntiClockwise90"
        case .oneEighty:
            paramValue = "180"
        }
        FTNotebookEventTracker.trackNotebookEvent(with: setting.eventName)
    }
}
