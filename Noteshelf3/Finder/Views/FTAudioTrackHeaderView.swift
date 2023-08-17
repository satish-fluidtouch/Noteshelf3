//
//  FTAudioTrackHeaderView.swift
//  Noteshelf3
//
//  Created by Sameer on 26/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit
import FTCommon

protocol FTAudioHeaderViewDelegate: AnyObject {
    func didTapToggleButton(isCollapsed: Bool, annotation: FTAudioAnnotation)
    func didTapPlayCompleteAudio(with annotation: FTAudioAnnotation)
}

class FTAudioTrackHeaderView: UITableViewHeaderFooterView {
    @IBOutlet weak var pageNumberLabel: FTCustomLabel!
    @IBOutlet weak var chevronImage: UIImageView!
    @IBOutlet var titleLabel: FTCustomLabel?
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet var audioDuration: FTCustomLabel?
    weak var headerDelegate: FTAudioHeaderViewDelegate?
    var audioAnnotation = FTAudioAnnotation()
    private var isAnimating: Bool = false

    override func awakeFromNib() {
        super.awakeFromNib();
    }
    
    override var canBecomeFocused: Bool {
        return false
    }
    
    @IBAction func didTapPlayButton(_ sender: Any) {
        self.headerDelegate?.didTapPlayCompleteAudio(with: audioAnnotation)
    }
    
    var isCollapsed : Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: "collapsed_\(audioAnnotation.uuid)");
            UserDefaults.standard.synchronize();
        }
        get {
            return UserDefaults.standard.bool(forKey: "collapsed_\(audioAnnotation.uuid)") ;
        }
    }
    
    @IBAction func didTapToggleButton(_ sender: Any) {
        if self.isAnimating {
            return
        }
        self.isCollapsed = !isCollapsed
        self.isAnimating = true
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            guard let self = self else {
                return
            }
            self.chevronImage.transform = self.isCollapsed ? CGAffineTransform.identity :
                CGAffineTransform(rotationAngle: .pi/2.0)
        }) { [weak self] (_) in
            self?.isAnimating = false
        }
        runInMainThread(0.1) {[weak self] in
            guard let `self` = self else {
                return
            }
            self.headerDelegate?.didTapToggleButton(isCollapsed: self.isCollapsed, annotation: self.audioAnnotation)
        }
    }
    
    func cofigure(with annotation: FTAudioAnnotation?) {
        if let annotation = annotation  {
            audioAnnotation = annotation
            titleLabel?.text = annotation.audioName
            audioDuration?.text = DateFormatter.localizedString(from: Date(timeIntervalSinceNow: annotation.modifiedTimeInterval), dateStyle: .short, timeStyle: .short)
            if !self.isAnimating {
                self.chevronImage.transform = self.isCollapsed ? CGAffineTransform.identity :
                    CGAffineTransform(rotationAngle: .pi/2.0)
            }
            if let page = annotation.associatedPage {
                pageNumberLabel.text = "p.\(page.pageIndex() + 1)"
            }
        }
    }
    
    func updateUI(_ duration: CGFloat, state: AudioSessionState) {
            if state == .stateRecording {
            } else if state == .statePlaying {
                actionButton?.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
            } else {
                actionButton?.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
            }
    }
}
