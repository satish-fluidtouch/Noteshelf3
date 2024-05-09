//
//  FTScrollingDirectionViewController.swift
//  Noteshelf3
//
//  Created by Sameer Hussain on 06/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTScrollingDirectionViewController: UIViewController {

    @IBOutlet weak private var tabelView : UITableView!
    
    var contentSize = CGSize.zero
    
    private var titleArray = ["Horizontal","Vertical"]
    var iconArr = ["horizontalScrollingIcon","verticalScrollingIcon"]
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
        cell.titleLBl.text = titleArray[indexPath.row]
        cell.iconImg.image = UIImage(named:iconArr[indexPath.row])
        cell.selectionStyle = .none
        print("\(UserDefaults.standard.pageLayoutType.rawValue)")
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var direction : Int = indexPath.row == 0 ? 1 : 0
        if let direction = FTPageLayout(rawValue: direction) {
            UserDefaults.standard.pageLayoutType = direction
            FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.nbk_moresettings_scrolling_tap, params: ["segment": (direction == .horizontal) ? "horizontal" : "vertical"])
        }
    }
}
