//
//  FTWatchAudioActionsViewController.swift
//  Noteshelf
//
//  Created by Simhachalam on 08/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
@objc protocol FTWatchAudioActionsDelegate : NSObjectProtocol {
    func actionsViewController(_ actionsViewController: FTWatchAudioActionsViewController, didSelectAction audioAction:FTAudioAction);
}

class FTWatchAudioActionsViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {
    weak var delegate: FTWatchAudioActionsDelegate?;
    
    var actionContext = FTAudioActionContext.shelf;

    @IBOutlet var titleLabel:UILabel?
    
    @IBOutlet var tableView:UITableView!
    var audioActions:[FTAudioAction]! = []
    var currentSelectedAudio:FTWatchRecordedAudio?
    
    var audioActionsProvider:FTWatchAudioActionsProvider! = FTWatchAudioActionsProvider()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.audioActions = self.audioActionsProvider.actionsForAudio(self.currentSelectedAudio, actionContext: self.actionContext)
        self.titleLabel?.text = self.currentSelectedAudio!.audioTitle;
    }
    
    deinit {
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
    }

    //MARK:- UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.audioActions.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FTWatchAudioOptionsCell") as? FTWatchAudioOptionsCell else {
            fatalError("Couldnot find FTWatchAudioOptionsCell")
        }
        cell.titleLabel.text = self.audioActions[indexPath.row].displayTitle
        cell.titleLabel.addCharacterSpacing(kernValue: -0.32)
        cell.applyActionStyle(self.audioActions[indexPath.row].actionStyle)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? CGFloat.leastNonzeroMagnitude : 16.0
    }

    //MARK:- UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        self.delegate?.actionsViewController(self, didSelectAction: self.audioActions[indexPath.row])
    }
}
