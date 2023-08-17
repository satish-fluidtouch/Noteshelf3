//
//  FTWatchRecordedAudioCell.swift
//  Noteshelf
//
//  Created by Simhachalam on 31/01/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTWatchRecordedAudioCell: UITableViewCell {
    @IBOutlet weak var dateLabel : UILabel!
    @IBOutlet weak var durationLabel : UILabel!
    @IBOutlet weak var playButton : UIButton!
    @IBOutlet weak var iconChevron : UIImageView!
    
    @IBOutlet weak var activityIndicator : UIActivityIndicatorView!
    @IBOutlet weak var circularProgressView : RPCircularProgress!

    var audioFileUUID : String? {
        willSet {
            NotificationCenter.default.removeObserver(self);
        }
        didSet {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.didChangeCurrentPlayTime(_:)),
                                                   name: NSNotification.Name(rawValue: "FTAudioPlayerCurrentTimeDidChange"),
                                                   object: self.audioFileUUID);
            
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.didChangeCurrentPlayTime(_:)),
                                                   name: NSNotification.Name(rawValue: "FTAudioPlayerDidStartPlaying"),
                                                   object: self.audioFileUUID);

            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.didChangeCurrentPlayTime(_:)),
                                                   name: NSNotification.Name(rawValue: "FTAudioPlayerDidEndPlaying"),
                                                   object: self.audioFileUUID);

        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.circularProgressView.isHidden = true;
        let view = UIView()
        view.backgroundColor = UIColor.appColor(.black5)
        selectedBackgroundView = view

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc func didChangeCurrentPlayTime(_ notification : Notification)
    {
        if notification.name == NSNotification.Name(rawValue: "FTAudioPlayerCurrentTimeDidChange") {
            if let userInfo = notification.userInfo {
                let currentTime = userInfo["currentTime"] as! TimeInterval;
                let duration = userInfo["duration"] as! TimeInterval;
                self.circularProgressView.updateProgress(CGFloat(currentTime/duration));
            }
        }
        else if notification.name == NSNotification.Name(rawValue: "FTAudioPlayerDidStartPlaying") {
            self.circularProgressView.updateProgress(0, animated: false, initialDelay: 0, duration: 0, completion: nil);
            self.circularProgressView.isHidden = false;
        }
        else if notification.name == NSNotification.Name(rawValue: "FTAudioPlayerDidEndPlaying") {
            self.circularProgressView.updateProgress(1, animated: true, initialDelay: 0, duration: 0.1, completion: { [weak self] in
                DispatchQueue.main.async {
                    self?.circularProgressView.isHidden = true;
                }
            });
        }
    }
}
