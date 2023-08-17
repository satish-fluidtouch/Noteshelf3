//
//  FTAudioSessionCell.swift
//  Noteshelf3
//
//  Created by Sameer on 25/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles
import FTCommon

protocol FTAudioSessionDelegate: AnyObject {
    func didTapOnPlay(with model: FTAudioTrackModel, cell: UITableViewCell)
//    func didTapOnRecording()
}

class FTAudioSessionCell: UITableViewCell {
    @IBOutlet var titleLabel: FTCustomLabel?
    @IBOutlet var audioDuration: FTCustomLabel?
    @IBOutlet var actionButton: UIButton?
    weak var delegate: FTAudioSessionDelegate?
    var model: FTAudioTrackModel?
    var isLastCell = false
    @IBAction func didTapOnPlay(_ sender: Any) {

    }
    
    func configureCell(with model: FTAudioTrackModel?, index: Int, del: FTAudioSessionDelegate, isLastCell: Bool) {
        self.delegate = del
        self.model = model
        self.isLastCell = isLastCell
        if !isLastCell {
            let string = String.localizedStringWithFormat(NSLocalizedString("SessionNo", comment: "Session %d"), index)
            titleLabel?.text = string
            audioDuration?.text = FTUtils.timeFormatted(UInt(model?.duration() ?? 0))
            audioDuration?.isHidden = false
            actionButton?.tintColor = UIColor.appColor(.accent)
        } else {
            audioDuration?.isHidden = true
            titleLabel?.text = NSLocalizedString("ContinueRecording", comment: "Continue Recording")

            let configuration = UIImage.SymbolConfiguration(font: UIFont.appFont(for: .regular, with: 19))
            actionButton?.setImage(UIImage(systemName: "record.circle.fill", withConfiguration: configuration), for: .normal)
            actionButton?.tintColor = UIColor.appColor(.destructiveRed)
        }
    }
    
    private func refresh() {
        if !self.isSelected && !isLastCell {
            audioDuration?.text = FTUtils.timeFormatted(UInt(model?.duration() ?? 0))
            actionButton?.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.refresh()
    }
    
    func updateUI(_ duration: CGFloat, state: AudioSessionState) {
        if !isLastCell {
            if state == .stateRecording {
    //            subTitleLabel.textColor = AUDIO_RED_COLOR
            } else if state == .statePlaying {
                actionButton?.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
            } else {
                actionButton?.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
            }
            if(duration > 0){
                audioDuration?.text = FTUtils.timeFormatted(UInt(duration))
            }
        }
    }
}
