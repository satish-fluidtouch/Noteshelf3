//
//  FTToastHostController.swift
//  Noteshelf3
//
//  Created by Narayana on 15/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTCommon

enum FTToastTag: Int {
    case generalToastTag = 1000
    case notebookInfoToastTag = 1001
}

class FTToastBaseHostController<ContentView: View>: UIHostingController<ContentView> {
    class func getIfToastExists(over controller: UIViewController, for tag: FTToastTag) -> (toastExist: Bool, toastView: UIView?) {
        let currentWindow = UIApplication.shared.keyWindow
        var ifExists = false
        var reqView: UIView?
        if let window = currentWindow {
            if let subView = window.subviews.filter({ view in
                view.tag == tag.rawValue
            }).first {
                ifExists = true
                reqView = subView
            }
        }
        return (ifExists, reqView)
    }
}

class FTToastHostController: FTToastBaseHostController<FTToastView> {
    private init(toastConfig: FTToastConfiguration) {
        let toastView = FTToastView(toastConfig: toastConfig, callbackFunction: {
        })
        super.init(rootView: toastView)
    }

    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
    }

    class func showToast(from controller: UIViewController, toastConfig: FTToastConfiguration,centerY: CGFloat = 50) {
        let toastInfo = FTToastHostController.getIfToastExists(over: controller, for: FTToastTag.generalToastTag)
        if let window = UIApplication.shared.keyWindow, !toastInfo.toastExist {
            let hostingVc = FTToastHostController(toastConfig: toastConfig)
            hostingVc.view.center.y = centerY + centerY/2
            hostingVc.view.center.x = window.frame.width/2.0
            hostingVc.view.tag = FTToastTag.generalToastTag.rawValue
            window.addSubview(hostingVc.view)
            hostingVc.view.backgroundColor = .clear
            hostingVc.view.alpha = 0.0

            UIView.animate(withDuration: toastConfig.animationTime) {
                hostingVc.view.alpha = 1.0
#if !targetEnvironment(macCatalyst)
         //       hostingVc.view.center.y = toastConfig.getToastSize().height/2.0 + 24.0
                hostingVc.view.center.y = centerY + toastConfig.getToastSize().height/2.0 + 8.0
#else
                hostingVc.view.center.y = toastConfig.getToastSize().height/2.0 + 44.0
#endif
            } completion: { _ in
                if toastConfig.autoRemovalOfToast {
                    hostingVc.view.removeWithAnimation()
                }
            }
        }
    }
}

class FTBookInfoToastHostController: FTToastBaseHostController<FTNotebookInfoToastView> {
    private init(info: FTNotebookToastInfo) {
        let toastView = FTNotebookInfoToastView(info: info)
        super.init(rootView: toastView)
    }

    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
    }

    class func removeIfToastExists(from controller: UIViewController) {
        let toastInfo = FTBookInfoToastHostController.getIfToastExists(over: controller, for: FTToastTag.notebookInfoToastTag)
        if toastInfo.toastExist {
            toastInfo.toastView?.alpha = 0.0
            toastInfo.toastView?.layer.removeAllAnimations()
            toastInfo.toastView?.removeFromSuperview()
        }
    }

    class func showToast(from controller: UIViewController, info: FTNotebookToastInfo) {
        FTBookInfoToastHostController.removeIfToastExists(from: controller)
        if let window = UIApplication.shared.keyWindow {
            let hostingVc = FTBookInfoToastHostController(info: info)
            hostingVc.view.center.x = window.frame.width/2.0
            hostingVc.view.tag = FTToastTag.notebookInfoToastTag.rawValue
            window.addSubview(hostingVc.view)
            hostingVc.view.backgroundColor = .clear
            hostingVc.view.alpha = 0.0
            var insetBottom: CGFloat = 16.0
            if let window = UIApplication.shared.keyWindow {
                insetBottom += window.safeAreaInsets.bottom
            }
            hostingVc.view.center.y = window.frame.maxY - insetBottom - info.toastHeight/2.0
            UIView.animate(withDuration: 0.3) {
                hostingVc.view.alpha = 1.0
            } completion: { _ in
                UIView.animate(withDuration: 1.0, delay: 2.0) {
                    hostingVc.view.alpha = 0.0
                } completion: { _ in
                    hostingVc.view.removeFromSuperview()
                }
            }
        }
    }
}

private extension UIView {
    func removeWithAnimation(_ delay: CGFloat = 2.0) {
        runInMainThread(delay) {
            UIView.animate(withDuration: 0.3) {
                self.alpha = 0.0
            } completion: { _  in
                self.removeFromSuperview()
            }
        }
    }
}
