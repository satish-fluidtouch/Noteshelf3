//
//  FTStylusChooseActionViewController.swift
//  Noteshelf
//
//  Created by Matra on 06/02/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTStylusChooseActionDelegate: AnyObject {
    func chooseActionPicker(_ picker: FTStylusChooseActionViewController?, valueChanged newValue: RKAccessoryButtonAction)
}

class FTStylusChooseActionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    weak var delegate: FTStylusChooseActionDelegate?
    var tag: Int = 0

    var currentSelection: RKAccessoryButtonAction?
    @IBOutlet weak var tableView: UITableView?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.delegate = self
        self.tableView?.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNavigationBar( title: NSLocalizedString("ChooseAction", comment: ""), preferLargeTitle: false)
    }

    //MARK :- TableView Delegate
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 16.0 : .leastNonzeroMagnitude
   }
   

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
#if targetEnvironment(macCatalyst)
        return  FTGlobalSettingsController.macCatalystTopInset;
#else
        return .leastNonzeroMagnitude
#endif
   }
    
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? FTSettingsBaseTableViewCell
        #if !targetEnvironment(macCatalyst)
        cell?.labelTitle?.text = PressurePenEngine.title(for: RKAccessoryButtonAction(rawValue: indexPath.row))
        #endif
        if currentSelection != nil, currentSelection?.rawValue == indexPath.row {
            cell?.accessoryImageView.image = UIImage(named: "checkBlue")
        } else {
            cell?.accessoryImageView.image = nil
        }

        return cell!
    }

     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true);
        currentSelection = RKAccessoryButtonAction(rawValue: indexPath.row)
        track("settings_stylus", params: ["action" : "chooseAction", "value": "\(currentSelection?.rawValue ?? 0)"])
        delegate?.chooseActionPicker(self, valueChanged: currentSelection!)
        tableView.reloadData()
        self.navigationController?.popViewController(animated: true)
    }
}
