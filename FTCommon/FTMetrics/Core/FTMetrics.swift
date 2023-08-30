//
//  AnalyticsManager.swift
//  Metrics
//
//  Created by Akshay on 02/04/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import Firebase

public enum FTMetricsTracker: String {
    case firebase = "Firebase"
}

@objc
public enum FTMetricsLogLevel:Int {
    case none
    case debug
}
#if !targetEnvironment(macCatalyst)
public final class FTMetrics: NSObject {
    //Public
    @objc public static let shared = FTMetrics()

    //Private
    private var services = [FTMetricsService]()
    private var events = [String : FTEvent]();
    private var logLevel = FTMetricsLogLevel.none
    private let metricsQueue = DispatchQueue(label: "com.fluidtouch.metrics")

    private override init() {}

    /// Initialize this in Appdelegate after initializing all the necessary SDKs for Metrics Tracking.
    ///
    /// - Parameter trackers: firebase, apsflyer
    public class func start(with trackers:[FTMetricsTracker],
                            loglevel:FTMetricsLogLevel = .none) {
        shared.services.removeAll()
        shared.logLevel = loglevel

        for tracker in trackers {
            switch tracker {
            case .firebase:
                shared.services.append(FirebaseMetricsService())
            }
        }
        shared.debugLog("🏁 Configured with \(trackers.map{$0.rawValue})")
    }
}

//MARK:- Tracking
extension FTMetrics {
    
    @objc
    public func track(event: String, params: [String : Any]?, screeName: String?) {
        metricsQueue.async {
            for service in self.services {
                service.track(event: event, params: params,screenName: screeName)
            }
            self.debugLogEvent(event, params: params)
        }
    }
    
    /// Used to log debug information to the disk.
    ///
    /// - Parameters:
    ///   - log: Log String
    ///   - params: (optional) key-value pairs, as additional parameters.
    @objc
    public func writeLog(_ log: String, params:[String : Any]?) {
        metricsQueue.async {
            for service in self.services {
                if service is FTLoggingMetrics {
                    (service as? FTLoggingMetrics)?.writeLog(log, params: params)
                }
            }
        }
    }
    
    /// Use this method to track the error.
    ///
    /// - Parameters:
    ///   - errorID: errorID to show up in the Dashboard.
    ///   - params: (optional) key-value pairs, as additional parameters.
    @objc
    public func trackError(errorID: String, params: [String : Any]?) {
        metricsQueue.async {
            for service in self.services {
                service.recordError(errorID: errorID, params: params)
            }
            self.debugLog("Error \(errorID), \(params?.description ?? "")")
        }
    }
    
    /// Use this method to track the Screen Name and Screen Class.
    ///
    /// - Parameters:
    ///   - screenName: Name of the screen to track screenwise events in Analytics.
    ///   - screenClass: Name of the class to track screenwise events in Analytics.
    @objc
    public func trackScreen(with screenName: String, screenClass: String?) {
        for service in self.services {
            service.trackScreen(with: screenName, className: screenClass)
        }
    }
    
    
    /// Pass this
    ///
    /// - Parameter userId: user id to identify
    @objc
    public func setUserId(userId: String) {
        metricsQueue.async {
            for service in self.services {
                service.setUserId(userId: userId)
            }
        }
    }
    
    
    /// Use this to set user specific properties
    ///
    /// - Parameters:
    ///   - property: property value
    ///   - name: property key
    @objc
    public func setUserProperty(property: String, for name:String) {
        metricsQueue.async {
            for service in self.services {
                service.setUserProperty(property: property, for: name)
            }
        }
    }
    /// Start performance tracking using this method.
    /// - IMPORTANT: Make sure to stop the tracking after the usage, with "stopTrackingPerformance" method.
    /// - Parameters:
    ///   - event: event title.
    ///   - params: (optional) key-value pairs, as additional parameters.
    @objc
    public func startTrackingPerformance(for event:String, params:[String:Any]?) {
        metricsQueue.async {
            for service in self.services where service is FTPerformanceMetrics {
                (service as? FTPerformanceMetrics)?.startTrackingPerformance(for: event, params: params)
            }
            self.debugLogEvent(event, params: params)
        }
    }
    
    /// Increment the counter for any event, which needs to be monitored, how many times it occured.
    /// - IMPORTANT:This is currently supported by Firebase only. This will automatically startTrackingPerformance, if it is already not started. This method requires a "stopTrackingPerformance" to end tracking.
    ///
    /// - Parameters:
    ///   - event: event title.
    ///   - value: value to be incremented.
    @objc
    public func incrementPerformanceMetric(for event:String, by value: Int64) {
        metricsQueue.async {
            for service in self.services {
                (service as? FTPerformanceMetrics)?.incrementPerformanceMetric(for: event, by: value)
            }
            self.debugLogEvent(event)
        }
    }
    
    
    /// Use this to stop tracking the performance based events.
    ///
    /// - Parameters:
    ///   - event: event title.
    ///   - params: (optional) key-value pairs, as additional parameters.
    @objc
    public func stopTrackingPerformance(for event:String, params:[String:Any]?) {
        metricsQueue.async {
            for service in self.services {
                (service as? FTPerformanceMetrics)?.stopTrackingPerformance(for: event, params: params)
            }
            self.debugLogEvent(event, params: params)
        }
    }
    
}


//MARK:- Private Methods
private extension FTMetrics {

    private func debugLog(_ string:String) {
        if self.logLevel == .debug {
            print("FTMetrics:",string)
        }
    }

    private func debugLogEvent(_ event:String, timed: Bool? = nil, params:[String:Any]? = nil) {
        if self.logLevel == .debug {
            let firebase = "Firebase"
            let paramsDesc = params?.description ?? "nil"
            debugLog("◉ \(event), Params:\(paramsDesc) [\(firebase)]")
        }
    }
}
#endif
