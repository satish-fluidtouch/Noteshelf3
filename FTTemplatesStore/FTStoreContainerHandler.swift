//
//  FTStoreContainerHandler.swift
//  FTTemplatesStore
//
//  Created by Siva on 19/05/23.
//

import Foundation
import UIKit
import Combine
import FTCommon

//
//final class FTStoreContainerHandler {
//    internal var actionStream = PassthroughSubject<FTStoreContainerActions, Never>()
//    internal var cancellables = Set<AnyCancellable>()
//}


enum FTStorePremiumActions {
    case showUpgradeAlert(controller: UIViewController,feature: String?)
    case track(event: String, params: [String: Any]?, screenName: String?)
}

public final class FTStorePremiumPublisher {
    public static let shared = FTStorePremiumPublisher()
    private init() {}
    internal var actionStream = PassthroughSubject<FTStorePremiumActions, Never>()
    internal var cancellables = Set<AnyCancellable>()
    public weak var premiumUser: FTPremiumUser?;
}
