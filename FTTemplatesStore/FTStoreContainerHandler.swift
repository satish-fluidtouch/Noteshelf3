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

public enum FTStoreContainerActions {
    case createNotebookForTemplate(url: URL, isLandscape: Bool, isDark: Bool)
    case createNotebookForDairy(fileName: String, title: String, startDate: Date, endDate: Date, coverImage: UIImage, isLandScape: Bool)
    case createNotebookFor(url: URL)
    case showUpgradeAlert(controller: UIViewController,feature: String?)
    case track(event: String, params: [String: Any]?, screenName: String?)
}

public final class FTStoreContainerHandler {
    public static let shared = FTStoreContainerHandler()
    private init() {}
    public var actionStream = PassthroughSubject<FTStoreContainerActions, Never>()
    public var cancellables = Set<AnyCancellable>()
    public weak var premiumUser: FTPremiumUser?;
}
