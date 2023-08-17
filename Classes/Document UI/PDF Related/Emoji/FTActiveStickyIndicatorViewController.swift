//
//  FTActiveStickyIndicatorViewController.swift
//  Noteshelf
//
//  Created by Amar on 12/6/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

@objc protocol FTActiveStickyIndicatorDelegate : NSObjectProtocol {
    func activeStickyIndicatorViewDidTapClose(indicatorView: FTActiveStickyIndicatorViewController)
    func activeStickyIndicatorViewDidTapEmoji(indicatorView: FTActiveStickyIndicatorViewController)
}

@objcMembers class FTActiveStickyIndicatorViewController: UIViewController {
    @IBOutlet private weak var backgroundColorView: UIView!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var dropButton: UIButton!

    @IBOutlet weak var activeStickerImageView: UIImageView?

    weak var delegate : FTActiveStickyIndicatorDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.backgroundColorView.layer.cornerRadius = self.backgroundColorView.frame.height * 0.25
        self.backgroundColorView.layer.borderColor = UIColor.gray.withAlphaComponent(0.2).cgColor
        self.backgroundColorView.layer.borderWidth = 0.5
        let closeButtonConfig = UIImage.SymbolConfiguration(font: UIFont.appFont(for: .semibold, with: 12))
        closeButton.setImage(UIImage(systemName: "multiply", withConfiguration: closeButtonConfig), for: .normal)
        let dropButtonConfig = UIImage.SymbolConfiguration(font: UIFont.appFont(for: .semibold, with: 11))
        dropButton.setImage(UIImage(systemName: "chevron.down", withConfiguration: dropButtonConfig), for: .normal)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setCurrentSelectedImage(_ image: UIImage) {
        self.activeStickerImageView?.image = image
    }
    
    @IBAction func didTapOnCloseButton(sender: UIButton) {
        self.delegate?.activeStickyIndicatorViewDidTapClose(indicatorView: self)
    }
    
    @IBAction func didTapOnEmojiButton(sender: UIButton) {
        self.delegate?.activeStickyIndicatorViewDidTapEmoji(indicatorView: self)
    }
}
