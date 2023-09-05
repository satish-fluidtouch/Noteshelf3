//
//  FirebaseMetricsService.swift
//  FTMetrics
//
//  Created by Akshay on 03/04/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAnalytics

final class FirebaseMetricsService: FTMetricsService {
   
    func track(event: String, params: [String : Any]?, screenName: String?) {
        if let name = screenName, !name.isEmpty{
            trackScreen(with: name, className: nil)
        }
        Analytics.logEvent(event, parameters: params)
    }
    
    
    func track(event: String, params: [String : Any]?) {
        Analytics.logEvent(event, parameters: params)
    }
    
    func recordError(errorID: String, params: [String : Any]?) {
        //Firebase doesn't support 
    }
    
    func setUserId(userId: String) {
        Analytics.setUserID(userId)
    }
    
    func setUserProperty(property: String, for name: String) {
        Analytics.setUserProperty(property, forName: name)
    }
    
    func trackScreen(with screenName: String, className: String?) {
        Analytics.logEvent(AnalyticsEventScreenView,
                           parameters: [AnalyticsParameterScreenName: screenName])
    }
}

extension FirebaseMetricsService: FTPerformanceMetrics {

    func startTrackingPerformance(for event: String, params: [String : Any]?) {
//        Performance.startTrace(name: event)
    }

    func incrementPerformanceMetric(for event: String, by value: Int64) {
//        var trace = Performance.sharedInstance().trace(name: event)
//        if trace == nil {
//            trace = Performance.startTrace(name: event)
//        }
//        trace?.incrementMetric(event, by: value)
    }

    func stopTrackingPerformance(for event: String, params: [String : Any]?) {
//        let trace = Performance.sharedInstance().trace(name: event)
//        trace?.stop()
    }
}
