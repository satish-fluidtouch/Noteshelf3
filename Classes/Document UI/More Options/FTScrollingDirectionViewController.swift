//
//  FTScrollingDirectionViewController.swift
//  Noteshelf3
//
//  Created by Sameer Hussain on 06/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

class FTScrollingDirectionViewController: UIViewController {
    @IBOutlet weak private var tabelView : UITableView!
    var contentSize = CGSize.zero
    
    private var dataModel = [FTPageLayout.horizontal, FTPageLayout.vertical]
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabelView.backgroundColor = .clear
        self.configureCustomNavigation(title: "Notebook Scrolling")
        self.tabelView.separatorInset = UIEdgeInsets(top:0, left: 0, bottom: 0, right: 0)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.contentSize != .zero {
            self.navigationController?.preferredContentSize = contentSize
        }
    }

}

extension FTScrollingDirectionViewController : UITableViewDataSource,UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier:"FTScrollingDirectionCell", for: indexPath) as? FTScrollingDirectionCell else { return UITableViewCell()}
        cell.titleLBl.text = dataModel[indexPath.row].localizedTitle
        let img = UIImage(named:dataModel[indexPath.row].toolIconName)
        cell.iconImg.image = img
        let layout = UserDefaults.standard.pageLayoutType.rawValue
        var AccessoryType : UITableViewCell.AccessoryType = indexPath.row == layout ? .none : .checkmark
        cell.accessoryType = AccessoryType
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataModel.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let layout = dataModel[indexPath.row]
        UserDefaults.standard.pageLayoutType = layout
        FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.nbk_moresettings_scrolling_tap, params: ["segment": (layout == .horizontal) ? "horizontal" : "vertical"])
        tableView.reloadData()
    }
}
