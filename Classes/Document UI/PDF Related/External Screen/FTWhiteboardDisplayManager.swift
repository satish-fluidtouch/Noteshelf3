//
//  FTWhiteboardDisplayManager.swift
//  Noteshelf
//
//  Created by Amar on 03/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

extension UIApplication
{
    func externalWindowScene(forScreen screen : UIScreen) -> UIWindowScene? {
        let sessions = self.connectedScenes;
        let sceneSession : UIScene? = sessions.first { (eachScene) -> Bool in
            if eachScene.session.role == .windowExternalDisplay,let scene = eachScene as? UIWindowScene,
                scene.screen == screen {
                return true;
            }
            return false;
        }
        return sceneSession as? UIWindowScene;
    }    
}

@objc extension FTWhiteboardDisplayManager {
    static var didChangePageDisplay : Notification.Name = Notification.Name("FTWhiteBoardDidChangePageDisplayNotification");
    static var didRecieveTouchOnPage : Notification.Name = Notification.Name("FTWhiteBoardDidRecieveTouchOnPageNotification");
}

@objcMembers class FTWhiteboardDisplayManager : NSObject
{
    static let shared = FTWhiteboardDisplayManager();

    private let maintainPrevStateOnExit = true;
    
    private var keyWindowHash : Int = 0;
    private var currentDisplayID : String = UUID().uuidString;
    
    private var externalWindow: UIWindow?;
    private var externalWindowScene: UIWindowScene?;
    
    private var _externalDisplayController : FTExternalScreenViewController?;
    private var externalDisplayController : FTExternalScreenViewController? {
        if(nil == _externalDisplayController) {
            if self.externalScreenAvailable(),let _extWindow = self.externalWindow {
                self.externalWindow?.rootViewController = nil;
                _externalDisplayController = FTExternalScreenViewController(externalWindow: _extWindow);
            }
        }
        return _externalDisplayController;
    }
        
    func configure() {
        
    }
    override init() {
        super.init();
        self.checkForExternalScreens();
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FTDidChangeWhiteBoardScreenValue,
                                               object: nil,
                                               queue: nil) { [weak self] (_) in
                                                self?.checkForExternalScreens();
        };
    }
    
    func setPage(page : FTPageProtocol,
                 onWindow : UIWindow,
                 presentationDelegate: FTLaserAnnotationHandler) -> String
    {
        let displayID = UUID().uuidString;
        if onWindow.isKeyWindow {
            if(onWindow.hashValue != self.keyWindowHash) {
                self.keyWindowHash = onWindow.hashValue;
            }
            self.currentDisplayID = displayID;
            self.externalDisplayController?.setPageToDisplay(page,
                                                             presentationDelegate: presentationDelegate);
        }
        return displayID;
    }
    
    func exitExternalScreen(_ window : UIWindow?,displayID : String?)
    {
        if !maintainPrevStateOnExit, self.currentDisplayID == displayID {
            self.exitExternalScreen(window);
        }
    }
    
    func isKeyWindow(_ window: UIWindow?) -> Bool {
        if let _window = window, _window.hashValue == self.keyWindowHash {
            return true;
        }
        return false;
    }
}

private extension FTWhiteboardDisplayManager
{
    func checkForExternalScreens() {
        if(UserDefaults.standard.bool(forKey: whiteBoardEnableKey)) {
            NotificationCenter.default.addObserver(forName: UIWindow.didBecomeKeyNotification,
                                                   object: nil,
                                                   queue: nil) { [weak self] (_) in
                if !(self?.maintainPrevStateOnExit ?? false) {
                    self?.screenDidConnect();
                }
            };

            NotificationCenter.default.addObserver(forName: UIScreen.didConnectNotification,
                                                   object: nil,
                                                   queue: nil)
            { [weak self] (note) in
                
                if let screen = note.object as? UIScreen,let windowScene = UIApplication.shared.externalWindowScene(forScreen: screen) {
                    self?.externalWindowScene = windowScene;
                    self?.screenDidConnect();
                }
                else {
                    self?.startListeningForExternalWindowSceneConnection();
                }
            };
            
            NotificationCenter.default.addObserver(forName: UIScreen.didDisconnectNotification,
                                                   object: nil,
                                                   queue: nil)
            { [weak self] (_) in
                self?.screenDidDisconnect();
            };
            
            if(externalScreenAvailable()) {
                self.screenDidConnect();
            }
        }
        else {
            self.screenDidDisconnect();
        }
    }
                
    func screenDidConnect()
    {
        self.screenDidDisconnect();
        if self.externalScreenAvailable() {
            self.addExternalWindowIfNeeded();
            NotificationCenter.default.post(name: NSNotification.Name.FTExternalDisplayDidConnected, object: nil);
        }
    }
    
    func screenDidDisconnect()
    {
        _externalDisplayController?.exitExternalScreen();
        _externalDisplayController = nil;
        self.keyWindowHash = 0;
        self.externalWindow = nil;
    }
    
    func externalScreenAvailable() -> Bool {
        self.updatedExternalDisplayIfAvailbale();
        if UserDefaults.standard.bool(forKey: whiteBoardEnableKey),
           nil != self.externalWindowScene {
            return true;
        }
        return false;
    }
    
    func exitExternalScreen(_ window : UIWindow?) {
        if let windowHash = window?.hashValue,self.keyWindowHash == windowHash {
            self.screenDidDisconnect();
        }
    }
}

private extension FTWhiteboardDisplayManager
{
    func startListeningForExternalWindowSceneConnection()
    {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.externalScreenDidConnected(_:)),
                                               name: UIScene.willConnectNotification,
                                               object: nil);
    }
    
    @objc func externalScreenDidConnected(_ notification: Notification) {
        if let windowScene = notification.object as? UIWindowScene,
            windowScene.session.role == .windowExternalDisplay,
            windowScene.screen == UIScreen.screens.last {
            self.externalWindowScene = windowScene;
            self.stopListeningForExternalWindowSceneConnection();
            self.screenDidConnect();
        }
    }
    
    func stopListeningForExternalWindowSceneConnection()
    {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIScene.willConnectNotification,
                                                  object: nil)
    }
    
    private func updatedExternalDisplayIfAvailbale() {
        guard nil == self.externalWindowScene,
              UserDefaults.standard.bool(forKey: whiteBoardEnableKey) else {
            return;
        }
        let screens = UIScreen.screens;
        for eachScreen in screens.reversed() {
            if let windowSceen = UIApplication.shared.externalWindowScene(forScreen: eachScreen) {
                self.externalWindowScene = windowSceen;
                break;
            }
        }
    }
}

private extension FTWhiteboardDisplayManager {
    func addExternalWindowIfNeeded() {
        guard nil == self.externalWindow,
              let extScreen = self.externalWindowScene?.screen else {
            return;
        }
        
        let extWindow = UIWindow(frame: extScreen.bounds);
        extWindow.isHidden = false;
        extWindow.windowScene = self.externalWindowScene;
        
        let launchInstanceStoryboard = UIStoryboard(name: "Launch Screen", bundle: nil);
        let viewController = launchInstanceStoryboard.instantiateInitialViewController();
        extWindow.rootViewController = viewController;
        
        self.externalWindow = extWindow
    }
}
