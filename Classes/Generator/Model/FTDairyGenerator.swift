//
//  FTDairyGenerator.swift
//  Template Generator
//
//  Created by Amar on 13/11/19.
//  Copyright © 2019 Amar. All rights reserved.
//

import UIKit
import PDFKit

let useTestTemplates = false;

class FTDairyGenerator: NSObject {
    private var format : FTDairyRenderFormat;
    private var monthlyFormatter : FTYearInfoMonthly;
    private var weeklyFormatter : FTYearInfoWeekly;
    private var formatInfo : FTYearFormatInfo;
    
    private var pageRect : CGRect = CGRect.zero;
    private let isLinking: Bool = false;
    var offsetCount: Int = 76 // used to open the current day page on diary creation
    private var variants: FTPaperVariants
    private var displayName : String

    
    required init(_ theme: FTAutoTemlpateDiaryTheme ,format inFormat: FTDairyRenderFormat, formatInfo : FTYearFormatInfo) {
        format = inFormat;
        self.formatInfo = formatInfo;
        monthlyFormatter = FTYearInfoMonthly.init(formatInfo: formatInfo);
        weeklyFormatter = FTYearInfoWeekly.init(formatInfo: formatInfo);
        self.displayName = theme.displayName
        self.variants = theme.customvariants!
        super.init()
    }
    
    func generate() -> URL {
        if !isLinking {
            monthlyFormatter.generate();
            weeklyFormatter.generate();
        }
        let orientation = (variants.isLandscape) ? FTDeviceOrientation.land : FTDeviceOrientation.port
        let key = self.displayName + "_" + orientation.rawValue +  "_" + self.variants.selectedDevice.dimension + "_DiaryTemplate"
        let path = self.rootPath.appendingPathComponent(key).appendingPathExtension("pdf")
        self.pageRect = format.pageRect();
        let isToDisplayOutOfMonthDate = format.isToDisplayOutOfMonthDate()
        
        UIGraphicsBeginPDFContextToFile(path.path, pageRect, nil);
        if let context = UIGraphicsGetCurrentContext() {
            format.generateCalendar(context: context, monthlyFormatter: monthlyFormatter, weeklyFormatter: weeklyFormatter)
        }
        
        UIGraphicsEndPDFContext();
        //start adding links
        format.addCalendarLinks(url: path, format: format as! FTDairyFormat, pageRect: pageRect, calenderYear: self.formatInfo, isToDisplayOutOfMonthDate: isToDisplayOutOfMonthDate, monthlyFormatter: monthlyFormatter, weeklyFormatter: weeklyFormatter)
        self.offsetCount = format.calendarOffsetCount()
        return path
    }
    
    func getOffset(date:Date) -> Int {
        return Date().numberOfDays(calendarYear: formatInfo)
    }
    func isBelongToCalendar(currentDate: Date, startDate: Date, endDate: Date) -> Bool{
        return (currentDate.compare(startDate) == ComparisonResult.orderedSame ||
            currentDate.compare(startDate) == ComparisonResult.orderedDescending)
            && (currentDate.compare(endDate) == ComparisonResult.orderedSame ||
                currentDate.compare(endDate) == ComparisonResult.orderedAscending)
    }
    
    private var rootPath : URL {
        let currentLang = formatInfo.locale;
        var rootPathURL = NSURL.fileURL(withPath: NSTemporaryDirectory());
        
        if(useTestTemplates) {
            rootPathURL = rootPathURL.appendingPathComponent("Test");
        }
        
        let fileManager = FileManager();
        if(!fileManager.fileExists(atPath: rootPathURL.path)) {
            try? fileManager.createDirectory(at: rootPathURL, withIntermediateDirectories: true, attributes: nil);
        }
        return rootPathURL;
    };
}
