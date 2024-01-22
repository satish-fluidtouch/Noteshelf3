//
//  FTGestureHelp.swift
//  Noteshelf
//
//  Created by Sameer on 30/08/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTGestureHelpViewController: UIViewController, UITableViewDataSource, FTCustomPresentable {
    var customTransitioningDelegate = FTCustomTransitionDelegate(with: .interaction)
    
    @IBOutlet weak var tableView: UITableView!
    
    private lazy var gestureOptions: [FTGestureHelpOptions] = {
    if isDeviceSupportsApplePencil(), FTStylusPenApplePencil().isConnected {
        return [.showPageThumbnails, .showQuickAccessSideBar,.activeFocusMode,.fitPageToScreen,.undo,.redo]
    } else {
        return [.showPageThumbnails, .showQuickAccessSideBar,. activeFocusMode, .undo, .redo]
    }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.separatorStyle = .singleLine
        self.tableView.estimatedRowHeight = 56.0
#if targetEnvironment(macCatalyst)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done".localized, style: .done, target: self, action: #selector(self.didTapOnclose(_:)));
#endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNavigationBar(hideBackButton: true, title: "Gesture".localized)
    }
    
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.gestureOptions.count
    }
      
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FTGestureHelpCell",for: indexPath) as? FTGestureHelpTableViewCell else {
            fatalError("Programmer error - Couldnot find FTGestureHelpTableViewCell")
        }
            let gesture = self.gestureOptions[indexPath.row]
            cell.configureGestureCell(with: gesture)
        return cell
    }
    
    static func presentGestureHelpScreen(controller: UIViewController) {
        let storyboard = UIStoryboard.init(name: "FTNotebookMoreOptions", bundle: nil);
        if let gestureHelpController = storyboard.instantiateViewController(withIdentifier: FTGestureHelpViewController.className) as? FTGestureHelpViewController {
                let navController = UINavigationController(rootViewController: gestureHelpController)
                controller.ftPresentFormsheet(vcToPresent: navController, hideNavBar: false, completion: nil)
        }
    }
    
#if targetEnvironment(macCatalyst)
    @objc func didTapOnclose(_ sender:Any?) {
        self.dismiss(animated: true);
    }
#endif
}
