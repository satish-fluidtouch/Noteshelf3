//
//  FTStickerPlacementView.swift
//  Noteshelf
//
//  Created by Amar on 25/05/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objc protocol FTStickerPlacementViewDelegate: AnyObject {
    func placeSticker(in rect: CGRect,sticker:UIImage?,emojiID: Int);
    func willBeginStickerPlacement(in rect:CGRect,sticker:UIImage?,emojiID: Int);
}

@objcMembers class FTStickerPlacementView: UIView {
    private(set) weak var activeSticker: UIImageView?;
    private(set) var activeEmojiID: Int = 0;
    weak var delegate: FTStickerPlacementViewDelegate?;
    
    override init(frame: CGRect) {
        super.init(frame:frame);
        self.layer.zPosition = 1;
        self.autoresizingMask = [.flexibleWidth,.flexibleHeight];
        
        let stickerImageView = UIImageView(frame:CGRect(x:0,y:0,width:32,height:32));
        self.addSubview(stickerImageView);
        stickerImageView.isHidden = true;
        self.activeSticker = stickerImageView;
        
        //Load the most recent sticker
        self.setCurrentSticky(image: self.latestStickyImage, emojiID: self.emojiIDHash);
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let _activeSticker = self.activeSticker else {
            return;
        }
        self.setCurrentSticky(image: self.latestStickyImage,emojiID:self.emojiIDHash);
        self.delegate?.willBeginStickerPlacement(in: _activeSticker.frame,
                                                 sticker: _activeSticker.image,
                                                 emojiID: self.activeEmojiID);
        if let touch = touches.first {
            _activeSticker.center = touch.location(in: self);
        }
        _activeSticker.isHidden = false;
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let _activeSticker = self.activeSticker, !_activeSticker.isHidden else {
            return;
        }
        
        UIView.animate(withDuration: 0.05, animations: {
            if let touch = touches.first {
                _activeSticker.center = touch.location(in: self);
            }
        });
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "DidMoveTouches"),
                                        object: self.window,
                                        userInfo: ["Touches" : touches]);
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard let _activeSticker = self.activeSticker,
            !_activeSticker.isHidden else {
                return;
        }

        self.activeSticker?.isHidden = true;
            
        self.delegate?.placeSticker(in:_activeSticker.frame,
                                    sticker:_activeSticker.image,
                                    emojiID:self.activeEmojiID);
        FTCLSLog("Sticker Placed")
    }
    

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        self.activeSticker?.isHidden = true
    }
    
    func setScale(_ scale: CGFloat)
    {
        guard let activeStickerImage = self.activeSticker else {
            return;
        }
        let center = activeStickerImage.center
        activeStickerImage.transform = CGAffineTransform(scaleX: scale, y: scale)
        activeStickerImage.center = center
    }
}

private extension FTStickerPlacementView {
    var latestStickyImage: UIImage {
        let lastUsedEmoji = self.emojiID
        let img = FTEmojiesManager().image(forEmojiString: lastUsedEmoji, size: 32)
        return img ?? UIImage();
    }
    
    var emojiID: String {
        let lastUsedEmoji = FTEmojiesManager().lastUsedEmoji()
        return lastUsedEmoji
    }
    
    var emojiIDHash: Int {
        return self.emojiID.hash
    }
    
    func setCurrentSticky(image: UIImage,emojiID:Int) {
        self.activeSticker?.image = image
        self.activeEmojiID = emojiID
    }
}
