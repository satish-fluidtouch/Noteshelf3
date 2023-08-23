//
//  FTToastHostController.swift
//  Noteshelf3
//
//  Created by Narayana on 15/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTCommon

let toastTag = 5858

class FTToastHostController: UIHostingController<FTToastView> {
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
}

private extension FTToastHostController {
    class func getIfToastExists(over controller: UIViewController) -> (toastExist: Bool, toastView: UIView?) {
        let currentWindow = controller.fetchCurrentWindow()
        var ifExists = false
        var reqView: UIView?

        if let window = currentWindow {
            if let subView = window.subviews.filter({ view in
                view.tag == toastTag
            }).first {
                ifExists = true
                reqView = subView
            }
        }
        return (ifExists, reqView)
    }
}

extension FTToastHostController {
    func updateToastInfo(from controller: UIViewController, toastConfig: FTToastConfiguration) {
        let toastInfo = FTToastHostController.getIfToastExists(over: controller)
        if toastInfo.toastExist {
            self.rootView.toastConfig.subTitle = toastConfig.subTitle
        }
    }

    @discardableResult
    class func showToast(from controller: UIViewController, toastConfig: FTToastConfiguration) -> FTToastHostController? {
        let toastInfo = FTToastHostController.getIfToastExists(over: controller)
        let currentWindow = controller.fetchCurrentWindow()
        if let window = currentWindow, !toastInfo.toastExist {
            let hostingVc = FTToastHostController(toastConfig: toastConfig)
            hostingVc.view.center.y = -50.0
            hostingVc.view.center.x = window.frame.width/2.0
            hostingVc.view.tag = toastTag
            window.addSubview(hostingVc.view)
            hostingVc.view.backgroundColor = .clear
            hostingVc.view.alpha = 0.0

            UIView.animate(withDuration: toastConfig.animationTime) {
                hostingVc.view.alpha = 1.0
#if !targetEnvironment(macCatalyst)
                hostingVc.view.center.y = toastConfig.getToastSize().height/2.0 + 24.0
#else
                hostingVc.view.center.y = toastConfig.getToastSize().height/2.0 + 44.0
#endif
            } completion: { _ in
                if toastConfig.autoRemovalOfToast {
                    hostingVc.view.removeWithAnimation()
                }
            }
            return hostingVc
        }
        return nil
    }

    func removeToastIfExists(controller: UIViewController) {
        let toastInfo = FTToastHostController.getIfToastExists(over: controller)
        if toastInfo.toastExist {
            guard let subView = toastInfo.toastView else {
                return
            }
            subView.removeWithAnimation(0.0)
        } else {
            self.view.removeFromSuperview()
        }
    }
}

private extension UIView {
    func removeWithAnimation(_ delay: CGFloat = 2.0) {
        runInMainThread(delay) {
            UIView.animate(withDuration: 0.3) {
                self.alpha = 0.0
                self.center.y = -50.0
            } completion: { _  in
                self.removeFromSuperview()
            }
        }
    }
}

private extension UIViewController {
    func fetchCurrentWindow() -> UIWindow? {
        var currentWindow = self.view.window?.windowScene?.windows.first
        if nil == currentWindow {
            if let scenes = UIApplication.shared.connectedScenes.first as? UIWindowScene, let window = scenes.windows.last {
                currentWindow = window
            }
        }
        return currentWindow
    }
}
