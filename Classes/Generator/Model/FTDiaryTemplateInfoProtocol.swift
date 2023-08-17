//
//  FTDiaryTemplateInfo.swift
//  Template Generator
//
//  Created by sreenu cheedella on 28/11/19.
//  Copyright © 2019 Amar. All rights reserved.
//

import UIKit

protocol FTDiaryTemplateInfoProtocol: NSObjectProtocol {
    var yearInfo:FTScreenYearSpacesInfo{get}
    var monthInfo:FTScreenMonthSpacesInfo{get}
    var weekInfo:FTScreenWeekSpacesInfo{get}
    var dayInfo:FTScreenDaySpacesInfo{get}
}

