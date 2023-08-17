//
//  FTNetworkPathMonitor.swift
//  FTNewNotebook
//
//  Created by Narayana on 11/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Network

// Can be optimized to handle network reavailable etc scenarios
class FTNetworkPathMonitor: NSObject {
    private var monitor: NWPathMonitor?

    func checkIfInternetIsAvailable(onCompletion: @escaping (Bool) -> Void) {
        monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "FTNetworkMonitor")
        monitor?.start(queue: queue)
        monitor?.pathUpdateHandler = { [weak self] path in
            guard let self else {
                return
            }
            let status: Bool = (path.status == .satisfied)
            self.cancelMonitoring()
            onCompletion(status)
        }
    }

    func cancelMonitoring() {
        monitor?.cancel()
    }
}
