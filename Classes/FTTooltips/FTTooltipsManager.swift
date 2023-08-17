//
//  FTTooltipsManager.swift
//  Noteshelf
//
//  Created by Simhachalam on 01/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
let FTUserDidTouchOnScreenNotification = "FTUserDidTouchOnScreenNotification"

@objcMembers class FTTooltipsManager: NSObject {
    var activeTooltips : [FTTooltipBubbleView] = []
    private static var shared : FTTooltipsManager?;
    var tipsInfoList:[FTTooltipModel]?
    class func sharedManager() -> FTTooltipsManager
    {
        if(nil == shared) {
            shared = FTTooltipsManager();
            do{
                shared?.tipsInfoList = []
                let bundlePlistURL = Bundle.main.url(forResource: "Tips", withExtension: "plist")
                let tipsInfoData = try Data(contentsOf: bundlePlistURL!);
                let tipsInfoArray:[[String : Any]] = try PropertyListSerialization.propertyList(from: tipsInfoData, options: [], format: nil) as! [[String : Any]];
                tipsInfoArray.forEach { (tipInfo) in
                    shared?.tipsInfoList?.append(FTTooltipModel.init(withDictionary: tipInfo))
                }
            }
            catch
            {
                
            }
            let expiredTooltipIDs = UserDefaults.standard.object(forKey: "ExpiredTooltipIDs")
            if(expiredTooltipIDs == nil)
            {
                UserDefaults.standard.set([], forKey: "ExpiredTooltipIDs")
                UserDefaults.standard.synchronize()
            }
        }
        return shared!;
    }
    
    var expiredTooltipIDs:[String]{
        get{
            return UserDefaults.standard.object(forKey: "ExpiredTooltipIDs") as! [String]
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "ExpiredTooltipIDs")
            UserDefaults.standard.synchronize()
        }
    }
    
    func registerGestures(){
        NotificationCenter.default.addObserver(self, selector: #selector(FTTooltipsManager.handleTapGesture), name: NSNotification.Name(rawValue: FTUserDidTouchOnScreenNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FTTooltipsManager.destroyVisibleTooltips), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    class func showTip(on window:UIWindow?, tipID:String , withTargetView targetView:Any){
        FTTooltipsManager.sharedManager().removeAllActiveTips()
        
        if(FTTooltipsManager.sharedManager().expiredTooltipIDs.contains(tipID)){
            return
        }
        guard let _window = window else { return }
        var targetRectInWindow:CGRect!
        if targetView is UIButton{
            targetRectInWindow = _window.convert((targetView as! UIButton).frame, from: (targetView as! UIButton).superview)
        }
        else if targetView is UIView{
            targetRectInWindow = CGRect.zero
        }
        
        let filteredModels = FTTooltipsManager.sharedManager().tipsInfoList!.filter({$0.tooltipID == tipID});
        if let newModel = filteredModels.first{
            var bubbleView: FTTooltipBubbleView!
            if newModel.tipDirection == FTTipDirection.top{
                bubbleView = FTTooltipBubbleView.init(withModel: newModel)
            }
            else if newModel.tipDirection == FTTipDirection.right{
                bubbleView = FTTooltipBubbleRight.init(withModel: newModel)
            }
            
            _window.addSubview(bubbleView)
            bubbleView.frame.origin = CGPoint.init(x: targetRectInWindow.midX - bubbleView.frame.width/2.0, y: targetRectInWindow.maxY - 10)
            bubbleView.registerForLayoutChanges(targetView)
            bubbleView.refreshTipBubble()
            bubbleView.refreshBubblePositions()
            bubbleView.alpha = 0.0
            UIView.animate(withDuration: 0.5) {
                bubbleView.alpha = 1.0
            }
            
            FTTooltipsManager.sharedManager().activeTooltips.append(bubbleView)
        }
    }
    func dismissTipForID(_ tipID:String , canExpireIfNeeded: Bool){
        let filteredTipBubbles = FTTooltipsManager.sharedManager().activeTooltips.filter({$0.tipModel.tooltipID == tipID});
        if filteredTipBubbles.count > 0{
            let tooltipBubble = filteredTipBubbles.first!
            if canExpireIfNeeded && tooltipBubble.tipModel.canExpire{
                var expiredIDs = self.expiredTooltipIDs
                expiredIDs.append(tooltipBubble.tipModel.tooltipID)
                self.expiredTooltipIDs = expiredIDs
            }
            
            UIView.animate(withDuration: 0.3, animations: {
                tooltipBubble.alpha = 0.0
            }, completion: { (success) in
                tooltipBubble.removeFromSuperview()
            })
            FTTooltipsManager.sharedManager().activeTooltips.remove(at: FTTooltipsManager.sharedManager().activeTooltips.index(of: tooltipBubble)!)
        }
        else if(canExpireIfNeeded) // If pen rack opened when tooltip not present
        {
            var expiredIDs = self.expiredTooltipIDs
            expiredIDs.append(tipID)
            self.expiredTooltipIDs = expiredIDs
        }
    }
    func destroyVisibleTooltips(){
        self.removeAllActiveTips()
    }
    internal func removeAllActiveTips(){
        FTTooltipsManager.sharedManager().activeTooltips.forEach { (tooltipBubble) in
            UIView.animate(withDuration: 0.3, animations: {
                tooltipBubble.alpha = 0.0
            }, completion: { (success) in
                tooltipBubble.removeFromSuperview()
            })
            FTTooltipsManager.sharedManager().activeTooltips.remove(at: FTTooltipsManager.sharedManager().activeTooltips.index(of: tooltipBubble)!)
        }
    }
    internal func handleTapGesture(){
        FTTooltipsManager.sharedManager().activeTooltips.forEach { (tooltipBubble) in
            if tooltipBubble.tipModel.shouldTapToDismiss == false{
                if tooltipBubble.tipModel.canExpire && tooltipBubble.tipModel.tipDirection != FTTipDirection.right{
                    var expiredIDs = self.expiredTooltipIDs
                    expiredIDs.append(tooltipBubble.tipModel.tooltipID)
                    self.expiredTooltipIDs = expiredIDs
                }
                
                UIView.animate(withDuration: 0.3, animations: {
                    tooltipBubble.alpha = 0.0
                }, completion: { (success) in
                    tooltipBubble.removeFromSuperview()
                })
                FTTooltipsManager.sharedManager().activeTooltips.remove(at: FTTooltipsManager.sharedManager().activeTooltips.index(of: tooltipBubble)!)
            }
        }
    }
}
