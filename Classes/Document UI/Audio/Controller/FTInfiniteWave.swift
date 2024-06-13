//
//  FTInfiniteWave.swift
//  FTStartUpScreen
//
//  Created by Prabhu on 6/7/17.
//  Copyright © 2017 Prabhu. All rights reserved.
//

import UIKit

@objcMembers class FTInfiniteWave: UIView {

    fileprivate var currentWidth : CGFloat = 0;
    fileprivate var forceLayout = false

    private var isLive = false
    private let slidingImage = UIImageView(image: UIImage(named: "infiniteSlider"))

    private weak var sceneActiveNotificationObserver: NSObjectProtocol?;
    
    deinit {
        if let observer = self.sceneActiveNotificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        NotificationCenter.default.removeObserver(self);
    }

    override func didMoveToWindow() {
        super.didMoveToWindow();
        self.setUp()
    }
    
    fileprivate func addObservers()
    {
        let notificationBlock : (_ noti:Notification) -> Void = { [weak self] (notification) in
            self?.forceLayout = true;
            self?.setNeedsLayout();
        }

        if #available(iOS 13.0, *) {
            self.sceneActiveNotificationObserver = NotificationCenter.default.addObserver(forName: UIScene.didActivateNotification,
                                                   object: self.window?.windowScene,
                                                   queue: nil,
                                                   using: notificationBlock)
        } else {
            self.sceneActiveNotificationObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                                   object: nil,
                                                   queue: nil,
                                                   using: notificationBlock)
        }
    }

    func start() {
        if(!isLive) {
            isLive = true
            prepareForStartAnimation()
        }
    }
    
    fileprivate func prepareForStartAnimation() {
        slidingImage.frame.origin = CGPoint.zero
        animate()
    }
    
    func stop() {
        isLive = false
        prepareForEndAnimations()
    }
    
    fileprivate func prepareForEndAnimations() {
        self.layer.removeAllAnimations()
        slidingImage.frame.origin = CGPoint.zero

    }
    fileprivate func setUp() {
        self.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        self.addSubview(slidingImage)
        slidingImage.frame.origin = CGPoint.zero
        self.addObservers();
    }
    
    fileprivate let duration = 1.0

    fileprivate func animate() {
        guard AVAudioSession.sharedInstance().recordPermission == .granted else {return};
        let durationToSet = max(((self.frame.width-self.slidingImage.frame.width)/400)*1,1);
        UIView.animate(withDuration: TimeInterval(durationToSet), delay: 0, options: [.curveLinear,.autoreverse,.repeat], animations: {
            self.slidingImage.frame.origin.x = self.frame.width-self.slidingImage.frame.width
        }, completion: {_ in
        })
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.slidingImage.frame.size = CGSize(width: 0.235 * self.bounds.width, height: self.bounds.height)
        if(isLive || self.forceLayout) {
            self.stop();
            let dispatchTime = DispatchTime.now() + DispatchTimeInterval.milliseconds(10)
            DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                self.start()
            })
        }
    }
}
