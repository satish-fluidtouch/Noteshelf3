//
//  FTNetwork.swift
//  FTTemplatesStore
//
//  Created by Siva on 17/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import Network

protocol FTNetworkObserver: AnyObject {
    func networkStatusDidChange(status: NWPath.Status)
}

class FTNetwork {
    // Usage
    ///     var networkCheck = FTNetwork.sharedInstance()
    //Add Observer
    /// networkCheck.addObserver(observer: self)
    ///
    // Listen Observer By Confirming FTNetworkObserver Protocol
    ///func networkStatusDidChange(status: NWPath.Status)

    struct FTNetworkChangeObservation {
        weak var observer: FTNetworkObserver?
    }

    private var monitor = NWPathMonitor()
    private static let _sharedInstance = FTNetwork()
    private var observations = [ObjectIdentifier: FTNetworkChangeObservation]()
    private var curStatus: NWPath.Status = .satisfied

    var currentStatus: NWPath.Status {
        get {
            return monitor.currentPath.status
        }
    }

    class func sharedInstance() -> FTNetwork {
        return _sharedInstance
    }

    init() {
        curStatus = currentStatus
        monitor.pathUpdateHandler = { [unowned self] path in
            for (id, observations) in self.observations {

                //If any observer is nil, remove it from the list of observers
                guard let observer = observations.observer else {
                    self.observations.removeValue(forKey: id)
                    continue
                }
                //It will post Network status on chage
                DispatchQueue.main.async(execute: {
                    observer.networkStatusDidChange(status: path.status)
                })
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }

    func addObserver(observer: FTNetworkObserver) {
        let id = ObjectIdentifier(observer)
        observations[id] = FTNetworkChangeObservation(observer: observer)
    }

    func removeObserver(observer: FTNetworkObserver) {
        let id = ObjectIdentifier(observer)
        observations.removeValue(forKey: id)
    }

}
