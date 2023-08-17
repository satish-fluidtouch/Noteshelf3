//
//  FTSelectExportFormatViewController.swift
//  Noteshelf
//
//  Created by Simhachalam on 03/01/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTSelectExportFormatDelegate: AnyObject {
    func exportFormatDidSelect(format newFormat:RKExportFormat);
}

extension UIViewController
{
    var exportControllerSafeAreaInset: UIEdgeInsets {
        var offset = UIEdgeInsets.zero;
        if let presentController = self.presentingViewController,
           !presentController.isRegularClass() {
            offset = presentController.view.safeAreaInsets;
        }
        return offset;
    }
}

class FTSelectExportFormatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    var exportFormats:[RKExportFormat]!
    var currentFormat:RKExportFormat!
    weak var delegate:FTSelectExportFormatDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let offset: CGFloat = self.exportControllerSafeAreaInset.bottom;
        self.preferredContentSize = CGSize(width: 320, height: 240 + offset);
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    //MARK:- UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.exportFormats.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ".noteshelf", for: indexPath) as! FTAccountSettingTableViewCell;
        cell.labelTitle?.text = "." + self.exportFormats[indexPath.row].filePathExtension()
        cell.imageViewIcon?.image = self.exportFormats[indexPath.row].image
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.accessoryType = (self.exportFormats[indexPath.row] == self.currentFormat) ? UITableViewCell.AccessoryType.checkmark : UITableViewCell.AccessoryType.none
        cell.backgroundColor = UIColor.appColor(.cellBackgroundColor)
        return cell;
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
    //MARK:- UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.currentFormat = self.exportFormats[indexPath.row]
        tableView.reloadData()
        self.delegate?.exportFormatDidSelect(format: self.currentFormat)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }    
}
