//
//  FTMetricsService.swift
//  Metrics
//
//  Created by Akshay on 02/04/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTMetricsService {

    func track(event: String, params:[String:Any]?)
    func track(event: String, params:[String:Any]?, screenName: String?)
    func recordError(errorID: String, params: [String : Any]?)

    ///User Specific Properties
    func setUserId(userId: String)
    func setUserProperty(property: String, for name:String)
    
    ///User screen tracking
    func trackScreen(with screenName: String, className: String?)

}

protocol FTLoggingMetrics {
    func writeLog(_ log:String, params:[String:Any]?)
}

protocol FTPerformanceMetrics {
    func startTrackingPerformance(for event:String, params:[String:Any]?)
    func incrementPerformanceMetric(for event: String, by value: Int64)
    func stopTrackingPerformance(for event:String, params:[String:Any]?)
}
