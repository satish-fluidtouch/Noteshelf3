//
//  FTModernDiaryFormat.swift
//  Noteshelf
//
//  Created by Narayana on 28/09/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

class FTModernDiaryFormat : FTDairyFormat {
    var customVariants : FTPaperVariants
    var weekNumberStrings : [String] = []
    var currentWeekRectInfo: FTDiaryWeekRectsInfo = FTDiaryWeekRectsInfo()
    var currentDayRectsInfo: FTDiaryDayRectsInfo = FTDiaryDayRectsInfo()
    var currentMonthRectsInfo: FTDiaryMonthRectsInfo = FTDiaryMonthRectsInfo()

    required init(customVariants : FTPaperVariants){
        self.customVariants = customVariants
        super.init()
    }

    var isiPad : Bool {
        return true
    }

    override var yearTemplate: String {
        return getModernAssetPDFPath(ofType: FTModernDiaryTemplateType.year, customVariants: formatInfo.customVariants)
    }

    override var monthTemplate: String {
        return getModernAssetPDFPath(ofType: FTModernDiaryTemplateType.monthly, customVariants: formatInfo.customVariants)
    }

    override var weekTemplate: String {
        return getModernAssetPDFPath(ofType: FTModernDiaryTemplateType.weekly, customVariants: formatInfo.customVariants)
    }
    
    override var dayTemplate: String {
        let templateType : FTModernDiaryTemplateType = .daily
        return getModernAssetPDFPath(ofType: templateType, customVariants: formatInfo.customVariants)
    }

    override func getYearCellHeight(rowCount: CGFloat) -> CGFloat {
        let templateInfo = screenInfo.spacesInfo.yearPageSpacesInfo
        return (currentPageRect.size.height - (currentPageRect.size.height*templateInfo.baseBoxY/100) - (currentPageRect.size.height*templateInfo.boxBottomOffset/100) - ((rowCount - 1) * (currentPageRect.size.height*templateInfo.cellOffsetY/100)))/rowCount
      }
      override func getYearCellWidth(columnCount: CGFloat) -> CGFloat {
        let templateInfo = screenInfo.spacesInfo.yearPageSpacesInfo
        return (currentPageRect.size.width - (2 * (currentPageRect.size.width*templateInfo.baseBoxX/100)) - ((columnCount - 1) * (currentPageRect.size.width*templateInfo.cellOffsetX/100)))/columnCount
      }

    func getModernAssetPDFPath(ofType type : FTModernDiaryTemplateType, customVariants variants: FTPaperVariants) -> String {
        var customVariants = variants
        let journalScreenType : String =  self.isiPad ? "ipad" :"iphone"
        let isiPad = (journalScreenType == "ipad") ? "1" : "0"
        customVariants.selectedDevice = FTDeviceModel(dictionary: ["displayName" : variants.selectedDevice.displayName.displayTitle,
                                                                   "dimension" : variants.selectedDevice.dimension,
                                                                   "identifier" : variants.selectedDevice.identifier,
                                                                   "dimension_land": variants.selectedDevice.dimension_land,
                                                                   "dimension_port":variants.selectedDevice.dimension_port,
                                                                   "isiPad" : isiPad])
        let orientation = customVariants.isLandscape ? "Land" : "Port"
        let screenType = customVariants.selectedDevice.isiPad ? "iPad" : "iPhone"
        let screenSize = FTModernDiaryFormat.getScreenSize(fromVariants: customVariants)
        let key = type.displayName + "_" + screenType + "_" + orientation +  "_" + "\(screenSize.width)" + "_"
            + "\(screenSize.height)"
        let pdfURL = self.rootPath.appendingPathComponent(key).appendingPathExtension("pdf")
        if FileManager.default.fileExists(atPath: pdfURL.path){
            return pdfURL.path
        } else {
            let templateDiaryInfo = FTModernDiaryTemplateInfo(templateType: type,customVariants: customVariants)
            let generator = FTModernDiaryTemplateAssetGenerator(templateInfo: templateDiaryInfo)
            let generatedPDFURL = generator.generate()
            return generatedPDFURL.path
        }
    }

    class func getFormatBasedOn(variants: FTPaperVariants) -> FTModernDiaryFormat {
        if !variants.selectedDevice.isiPad {
            return FTModernDiaryiPhoneFormat(customVariants: variants)
        }
        return  FTModernDiaryiPadFormat(customVariants: variants)
    }

    class func getScreenSize(fromVariants variants: FTPaperVariants) -> CGSize {
        let dimension = variants.isLandscape ? variants.selectedDevice.dimension_land : variants.selectedDevice.dimension_port
        let measurements = dimension.split(separator: "_")
        return CGSize(width: Int(measurements[0])!, height: Int(Double(measurements[1])!))
    }

    func renderModernDiaryPDF(context: CGContext, pdfTemplatePath path:String){
        UIGraphicsBeginPDFPage();
        let pageRect = UIGraphicsGetPDFContextBounds();
        
        let templatePath = path;
        let pdfDocument = PDFDocument.init(url: URL(fileURLWithPath: templatePath));
        let pdfPage = pdfDocument!.page(at: 0);
        
        context.saveGState();
        context.translateBy(x: 0, y: pageRect.size.height);
        context.scaleBy(x: 1, y: -1);
        pdfPage?.transform(context, for: .cropBox);
        pdfPage?.draw(with: .cropBox, to: context);
        context.restoreGState();
    }

    //MARK:- PDF Generation and linking between pages
    override func generateCalendar(context : CGContext, monthlyFormatter : FTYearInfoMonthly, weeklyFormatter : FTYearInfoWeekly) {
        // Render year page
        self.renderYearPage(context: context, months: monthlyFormatter.monthInfo, calendarYear: formatInfo);
        self.diaryPagesInfo.append(FTDiaryPageInfo(type: .year))

        // Render Month Pages
        let calendarMonths = monthlyFormatter.monthCalendarInfo;
        calendarMonths.forEach { (calendarMonth) in
            self.renderMonthPage(context: context, monthInfo: calendarMonth, calendarYear: formatInfo)
            self.diaryPagesInfo.append(FTDiaryPageInfo(type: .month))
        }
        
         // Render Week pages
        let weeklyInfo = weeklyFormatter.weeklyInfo
        weeklyInfo.forEach { (weekInfo) in
            self.renderWeekPage(context: context, weeklyInfo: weekInfo)
            self.diaryPagesInfo.append(FTDiaryPageInfo(type: .week))
        }

        // Render Day pages
        let monthInfo = monthlyFormatter.monthCalendarInfo;
        monthInfo.forEach { (eachMonth) in
            let dayInfo = eachMonth.dayInfo;
            dayInfo.forEach { (eachDayInfo) in
                if eachDayInfo.belongsToSameMonth {
                    self.renderDayPage(context: context, dayInfo: eachDayInfo);
                    if let utcDate = eachDayInfo.date.utcDate() {
                        diaryPagesInfo.append(FTDiaryPageInfo(type: .day,date: utcDate.timeIntervalSinceReferenceDate))
                    }
                }
            }
        }
    }

    override func renderYearPage(context: CGContext, months: [FTMonthInfo], calendarYear: FTYearFormatInfo) {
        super.renderYearPage(context: context, months: months, calendarYear: calendarYear)
        
        let yearFont = UIFont.robotoLight(screenInfo.fontsInfo.yearPageDetails.yearFontSize)
        let minimumFontSizeYear: CGFloat = isiPad ? 100.0 : 60.0
        var yearNewFontSize = UIFont.getScaledFontSizeFor(font: yearFont, screenSize: currentPageRect.size, minPointSize: minimumFontSizeYear)
        
        if UIDevice.current.isPhone() && self.customVariants.selectedDevice.identifier == "standard4" {
                yearNewFontSize -= yearNewFontSize * 0.3
        }

        let yearAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.robotoLight(yearNewFontSize),
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString: "#35383D")]
        if let startYear = months.first?.year {
            var year: String = "\(startYear)"
            if let endYear = months.last?.year, endYear != startYear {
                let endYearXX = "\(endYear)".suffix(2)
                year = "\(startYear)" +  "-" + "\(endYearXX)"
            }
            let isLandscape = self.formatInfo.customVariants.isLandscape
            let yearStrXPos: CGFloat = isiPad ? (isLandscape ? 3.59 : 4.31) : 5.33
            let yearStrYPos: CGFloat = isiPad ? (isLandscape ? 11.68 : 10.78) : 2.76
            let yearX: CGFloat = currentPageRect.width*yearStrXPos/100
            var yearY: CGFloat = currentPageRect.height*yearStrYPos/100
            
            if self.customVariants.selectedDevice.identifier == "standard4" {
                let extraOffset: CGFloat = 30.0
                yearY -= extraOffset
            }
            
            let yearString = NSMutableAttributedString.init(string: year, attributes: yearAttrs)
            let yearLocation = CGPoint(x: yearX, y: yearY)
            yearString.draw(at: yearLocation)
        }
        
        let templateInfo = screenInfo.spacesInfo.yearPageSpacesInfo
        var currMonthIndex = CGFloat(0)
        let columnCount = getColumnCount()
        let rowCount = getRowCount()
        let cellWidth = getYearCellWidth(columnCount: columnCount)
        let cellHeight = getYearCellHeight(rowCount: rowCount)

        var monthY = currentPageRect.height*templateInfo.baseBoxY/100
        if self.customVariants.selectedDevice.identifier == "standard4" {
            let extraOffset: CGFloat = 30.0
            monthY -= extraOffset
        }
        var monthX = currentPageRect.width*templateInfo.baseBoxX/100
        months.forEach { (month) in
            let monthFont = UIFont.robotoRegular(screenInfo.fontsInfo.yearPageDetails.titleMonthFontSize)
            let monthNewFontSize = UIFont.getScaledFontSizeFor(font: monthFont, screenSize: currentPageRect.size, minPointSize: 8)
            let monthAttrs : [NSAttributedString.Key: Any] = [.font : UIFont.robotoRegular(monthNewFontSize),
                                                              NSAttributedString.Key.kern : 0.0,
                                                              .foregroundColor : UIColor.init(hexString: "#35383D")]
            let monthString = NSMutableAttributedString(string: month.monthTitle, attributes: monthAttrs)
            
            let monthStringXPercentage : CGFloat = isiPad ? (formatInfo.customVariants.isLandscape ? 1.03 : 1.31) : 1.30
            let monthStringYPercentage : CGFloat = isiPad ? (formatInfo.customVariants.isLandscape ? 1.08 : 0.95) : 1.11
            let monthStringX = (currentPageRect.width*monthStringXPercentage)/100
            let monthStringY = (currentPageRect.height*monthStringYPercentage)/100
            
            let location = CGPoint(x: monthX + monthStringX, y: monthY + monthStringY)
            monthString.draw(at: location)
            yearRectsInfo.monthRects.append(getLinkRect(location: CGPoint(x: monthX, y: monthY), frameSize: CGSize(width: cellWidth ,height: cellHeight)))
            
            currMonthIndex+=1
            let numberOfColunms = columnCount
            if currMonthIndex.truncatingRemainder(dividingBy: numberOfColunms) == 0{
                monthY += cellHeight + (currentPageRect.height*templateInfo.cellOffsetY/100)
                monthX = currentPageRect.width*templateInfo.baseBoxX/100
            }
            else{
                monthX += cellWidth + (currentPageRect.size.width*templateInfo.cellOffsetX/100)
            }
        }
    }

    override func renderMonthPage(context: CGContext, monthInfo: FTMonthlyCalendarInfo, calendarYear: FTYearFormatInfo) {
        super.renderMonthPage(context: context, monthInfo: monthInfo, calendarYear: calendarYear)
        
        let isLandscape = self.formatInfo.customVariants.isLandscape
        currentMonthRectsInfo = FTDiaryMonthRectsInfo()

        // Month name rendering
        let monthFont = UIFont.robotoLight(screenInfo.fontsInfo.monthPageDetails.monthFontSize)
        let minimumFontSize = isiPad ? 100.0 : 60.0
        var monthNewFontSize = UIFont.getScaledFontSizeFor(font: monthFont, screenSize: currentPageRect.size, minPointSize: minimumFontSize)
        if isLandscape {
            if self.customVariants.selectedDevice.identifier == "standard4" || self.customVariants.selectedDevice.identifier == "standard1" {
                monthNewFontSize -= monthNewFontSize * 0.2
            }
        }
        
        let monthAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.robotoLight(monthNewFontSize),
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString: "35383D")]

        let monthString = NSMutableAttributedString.init(string: monthInfo.shortMonth.uppercased(), attributes: monthAttrs)
        let monthXpercentage: CGFloat = isiPad ? (isLandscape ? 3.59 : 5.03) : 5.33
        let monthYPecrcentage: CGFloat = isiPad ? (isLandscape ? 20.64 : 10.59) : 2.76
        let monthX: CGFloat = currentPageRect.width*monthXpercentage/100
        var monthY: CGFloat = currentPageRect.height*monthYPecrcentage/100
        if self.customVariants.selectedDevice.identifier == "standard4" || self.customVariants.selectedDevice.identifier == "standard2" || (self.customVariants.selectedDevice.identifier == "standard1" && isLandscape ) {
            let extraOffset: CGFloat = 10.0
            monthY -= extraOffset
        }
        
        if UIDevice.current.isPhone() && self.customVariants.selectedDevice.identifier == "standard4" && isLandscape {
            let extraOffset: CGFloat = 40.0
            monthY -= extraOffset
        }

        let monthLocation = CGPoint(x: monthX, y: monthY)
        monthString.draw(in: CGRect(x: monthLocation.x, y: monthLocation.y, width: monthString.size().width, height: monthString.size().height))

        // Year rendering
        let yearFont = UIFont.robotoRegular(screenInfo.fontsInfo.monthPageDetails.yearFontSize)
        let yearNewFontSize = UIFont.getScaledFontSizeFor(font: yearFont, screenSize: currentPageRect.size, minPointSize: 30)
        let yearAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.robotoRegular(yearNewFontSize),
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString: "A1A1A1")]

        let yearString = NSMutableAttributedString.init(string: monthInfo.year, attributes: yearAttrs)
        let yearXpercentage: CGFloat = isiPad ? (isLandscape ? 3.95 : 41.36) : 73.86
        let yearYPecrcentage: CGFloat = isiPad ? (isLandscape ? 37.14 : 19.84) : 9.80
        var yearX: CGFloat = currentPageRect.width*yearXpercentage/100
        var yearY: CGFloat = currentPageRect.height*yearYPecrcentage/100

        if isiPad && !isLandscape { // iPad template Portrait(iPhone+iPad)
            let gapBtwYearAndMonth: CGFloat = 5.03
            yearX = monthX + monthString.size().width + (currentPageRect.width*gapBtwYearAndMonth/100)
            let yearYOffset: CGFloat = 20.0
            yearY = monthY + monthString.size().height - yearString.size().height - yearYOffset
        } else if UIDevice.current.isPhone() { // iPhone Device
            if isLandscape {
                yearY = monthY + monthString.size().height
            } else {
                let yearYOffset: CGFloat = 20.0
                yearY = monthY + monthString.size().height - yearString.size().height - yearYOffset
            }
        } else if !isiPad && !isLandscape { // iPhone Template+Portrait
            let yearYOffset: CGFloat = 8.0
            yearY = monthY + monthString.size().height - yearString.size().height - yearYOffset
        }
        
        let yearLocation = CGPoint(x: yearX, y: yearY)
        yearString.draw(in: CGRect(x: yearLocation.x, y: yearLocation.y, width: yearString.size().width, height: yearString.size().height))
        currentMonthRectsInfo.yearRect = getLinkRect(location: yearLocation, frameSize: yearString.size())

        // Week Symbols Rendering
        let symbols = getWeekSymbols(monthInfo: monthInfo)
        
        let paragraphStyle = NSMutableParagraphStyle.init()
        paragraphStyle.alignment = .center
        let weekSymbolFont = UIFont.robotoRegular(screenInfo.fontsInfo.monthPageDetails.weekFontSize)
        let weekSymbolNewFontSize = UIFont.getScaledFontSizeFor(font: weekSymbolFont, screenSize: currentPageRect.size, minPointSize: 12)
        
        let symbolAttrs: [NSAttributedString.Key : Any] =  [.font :UIFont.robotoRegular(weekSymbolNewFontSize),
                                                            NSAttributedString.Key.kern : 0.0,
                                                            .foregroundColor : UIColor.init(hexString: "A2A2A2"),
                                                            .paragraphStyle: paragraphStyle]
        
        let templateInfo = screenInfo.spacesInfo.monthPageSpacesInfo
        let cellWidth = (currentPageRect.width - (currentPageRect.width*templateInfo.baseBoxX/100) - (currentPageRect.width*templateInfo.boxRightOffset/100))/7

        let symbolXPercentage: CGFloat = isiPad ? (isLandscape ? 0.58 : 0.58) : 1.69
        let symbolYPercentage: CGFloat = isiPad ? (isLandscape ? 2.98 : 1.24) : 1.81
        
        let symbolXOffset: CGFloat = currentPageRect.width*symbolXPercentage/100
        var symbolYOffset: CGFloat = currentPageRect.height*symbolYPercentage/100
        if self.customVariants.selectedDevice.identifier == "standard4" && !isLandscape {
            let extraOffset: CGFloat = 10.0
            symbolYOffset += extraOffset
        }

        var symbolX = (currentPageRect.width*templateInfo.baseBoxX/100) + symbolXOffset
        symbols.forEach({(symbol) in
            let symbolString = NSMutableAttributedString.init(string: symbol,attributes: symbolAttrs)
            let symbolY = (currentPageRect.height*templateInfo.baseBoxY/100) - (symbolString.size().height) - symbolYOffset
            symbolString.draw(in: CGRect(x: symbolX, y:symbolY, width: symbolString.size().width, height: symbolString.size().height))
            symbolX += cellWidth
        })

        // Days Rendering
        var dayX = (currentPageRect.width*templateInfo.baseBoxX/100)
        var linkX = (currentPageRect.width*templateInfo.baseBoxX/100)
        var dayY = (currentPageRect.height*templateInfo.baseBoxY/100)
        if self.customVariants.selectedDevice.identifier == "standard4" && !isLandscape {
            let extraOffset: CGFloat = 10.0
            dayY -= extraOffset
        }

        var index = 1
        
        monthInfo.dayInfo.forEach({(day) in
            let dayForeGroundColor = day.belongsToSameMonth ? UIColor.init(hexString: "35383D") :UIColor(hexString: "C2C0C0", alpha: 0.8)
            let dayFont = UIFont.robotoRegular(screenInfo.fontsInfo.monthPageDetails.dayFontSize)
            let dayNewFontSize = UIFont.getScaledFontSizeFor(font: dayFont, screenSize: currentPageRect.size, minPointSize: 12)
            let dayAttrs: [NSAttributedString.Key: Any] = [.font :UIFont.robotoRegular(dayNewFontSize),
                                                           NSAttributedString.Key.kern : 0.0,
                                                           .foregroundColor : dayForeGroundColor,
                                                           .paragraphStyle: paragraphStyle];
            let dayString = NSMutableAttributedString.init(string: day.dayString, attributes: dayAttrs)
            let drawRect = CGRect(x: dayX+6.0, y: dayY+3.0, width: dayString.size().width, height: dayString.size().height)
            let drawLocation = CGPoint(x: drawRect.origin.x, y: drawRect.origin.y)

            let cellHeight = (currentPageRect.height - (currentPageRect.height*templateInfo.baseBoxY/100) - (currentPageRect.height*templateInfo.boxBottomOffset/100))/6

            if day.belongsToSameMonth {
                let cellOffsetX:CGFloat = 10
                let cellOffsetY :CGFloat = 6
                let minLength = CGFloat(30)
                let attr = NSAttributedString.init(string: day.dayString,
                                                   attributes: dayAttrs)
                let rectWidth = 2*cellOffsetX + attr.size().width
                let rectHeight = 2*cellOffsetY + attr.size().height
                let linkRect = CGRect(x: linkX, y: pageRect().height - dayY - (rectHeight >= minLength ? rectHeight : minLength),
                                                             width: rectWidth >= minLength ? rectWidth : minLength,
                                                             height: rectHeight >= minLength ? rectHeight : minLength)
                dayString.draw(at:drawLocation)
                currentMonthRectsInfo.dayRects.append(linkRect)
            }

            if(index % 7 == 0) {
                dayX = (currentPageRect.width*templateInfo.baseBoxX/100)
                linkX = (currentPageRect.width*templateInfo.baseBoxX/100)
                dayY += cellHeight
            }
            else {
                dayX += cellWidth
                linkX += cellWidth
            }
            index += 1
        })
        monthRectsInfo.append(currentMonthRectsInfo)
        
        // Week numbers rendering
        let weekFont = UIFont.robotoRegular(screenInfo.fontsInfo.monthPageDetails.weekFontSize)
        let weekNewFontSize = UIFont.getScaledFontSizeFor(font: weekFont, screenSize: currentPageRect.size, minPointSize: 12)
        let weekNumberTextAttribute: [NSAttributedString.Key : Any] = [.font : UIFont.robotoRegular(weekNewFontSize),
                                                                       NSAttributedString.Key.kern : 0.0,
                                                                       .foregroundColor : UIColor(hexString: "A1A1A1")]
        
        let weekXPercentage: CGFloat = isiPad ? (isLandscape ? 3.32 : 3.95) : 4.26
        let weekYPercentage: CGFloat = isiPad ? (isLandscape ? 2.53 : 2.77) : 1.78
        
        let weekXOffset: CGFloat = currentPageRect.width*weekXPercentage/100
        let weekYOffset: CGFloat = currentPageRect.height*weekYPercentage/100

        let weekX = (currentPageRect.width*templateInfo.baseBoxX/100) - weekXOffset
        var weekY = (currentPageRect.height*templateInfo.baseBoxY/100) + weekYOffset
        if self.customVariants.selectedDevice.identifier == "standard4" && !isLandscape {
            let extraOffset: CGFloat = 10.0
            weekY -= extraOffset
        }

        let cellHeight = (currentPageRect.height - (currentPageRect.height*templateInfo.baseBoxY/100) - (currentPageRect.height*templateInfo.boxBottomOffset/100))/6

        weekNumberStrings.removeAll()
        if let date = monthInfo.dayInfo.first?.date {
            var component = Calendar.current.component(.weekOfYear, from: date)
            if monthInfo.shortMonth == "Jan" {
                component = 1
            }
            for index in 0...3 {
                weekNumberStrings.append("Wk \(component+index)")
            }
            
            // To check if 5th week exists in a month
            if 28 < monthInfo.dayInfo.count {
                if monthInfo.dayInfo[28].belongsToSameMonth {
                    weekNumberStrings.append("Wk \(component+4)")
                }
            }
            
            // To check if 6th week exists in a month
            if 35 < monthInfo.dayInfo.count {
                if monthInfo.dayInfo[35].belongsToSameMonth {
                    weekNumberStrings.append("Wk \(component+5)")
                }
            }
        }
        
        for week in weekNumberStrings {
            let weekString = NSMutableAttributedString.init(string: week,attributes: weekNumberTextAttribute)
            let location = CGPoint(x: weekX - weekString.size().width, y: weekY)
            weekString.draw(at: location)
            weekY += cellHeight
            currentMonthRectsInfo.weekRects.append(getLinkRect(location: location, frameSize: weekString.size()))
        }
        
    }
    
    override func renderWeekPage(context: CGContext, weeklyInfo: FTWeekInfo) {
        super.renderWeekPage(context: context, weeklyInfo: weeklyInfo)
        let isLandscape = self.formatInfo.customVariants.isLandscape
        currentWeekRectInfo  = FTDiaryWeekRectsInfo()
        // Rendering week range string
        let weekRangeXposPercentage: CGFloat = isiPad ? (isLandscape ? 3.95 : 5.39) : 5.6
        let weekRangeYPosPercentage: CGFloat = isiPad ? (isLandscape ? 5.06 : 5.15) : 4.41
        let weekRangeXpos: CGFloat = currentPageRect.width*weekRangeXposPercentage/100
        var weekRangeYpos: CGFloat = currentPageRect.height*weekRangeYPosPercentage/100

        if UIDevice.current.isPhone() && self.customVariants.selectedDevice.identifier == "standard4" {
            weekRangeYpos -= 10.0
        }
        
        let weekRangeFont = UIFont.robotoRegular(isiPad ? 14 : 12)
        let weekRangeNewFontSize = UIFont.getScaledFontSizeFor(font: weekRangeFont, screenSize: currentPageRect.size, minPointSize: isiPad ? 10 : 8)
        let weekRangeAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.robotoRegular(weekRangeNewFontSize),
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString:"35383D")]
        
        let weekFirstDate = weeklyInfo.dayInfo.first
        let weekLastDate = weeklyInfo.dayInfo.last
        var weekDurationText : String = ""
        
        let monthAttrs: [NSAttributedString.Key: Any] = weekRangeAttrs

        if weekFirstDate?.month == weekLastDate?.month {
            let month = isiPad ? (weeklyInfo.dayInfo.first?.fullMonthString.uppercased() ?? "") : (weeklyInfo.dayInfo.first?.monthString.uppercased() ?? "")
            let monthString = NSMutableAttributedString.init(string: month, attributes: monthAttrs)
            weekDurationText =  (weeklyInfo.dayInfo.first?.fullDayString ?? "")
            weekDurationText += " " + monthString.string + " - "
            weekDurationText += (weeklyInfo.dayInfo.last?.fullDayString ?? "") + " " + monthString.string
        }
        else{
            let weekFirstDayMonth = isiPad ? (weeklyInfo.dayInfo.first?.fullMonthString.uppercased() ?? "") : (weeklyInfo.dayInfo.first?.monthString.uppercased() ?? "")
            let weekFirstDaysMonth = NSMutableAttributedString.init(string: weekFirstDayMonth, attributes: monthAttrs)
            weekDurationText += (weeklyInfo.dayInfo.first?.fullDayString ?? "") + " " + weekFirstDaysMonth.string
            weekDurationText += " " + "-" + " "
            let weekLastDayMonth = isiPad ? (weeklyInfo.dayInfo.last?.fullMonthString.uppercased() ?? "") : (weeklyInfo.dayInfo.last?.monthString.uppercased() ?? "")
            let weekLastDaysMonth = NSMutableAttributedString.init(string: weekLastDayMonth, attributes: monthAttrs)
            weekDurationText +=   (weeklyInfo.dayInfo.last?.fullDayString ?? "") + " " + weekLastDaysMonth.string
        }

        let weekRangeString = NSMutableAttributedString.init(string: weekDurationText, attributes: weekRangeAttrs)
        let weekRangeLocation = CGPoint(x: weekRangeXpos, y: weekRangeYpos)
        weekRangeString.draw(at: weekRangeLocation)

        // Draw horizantal divider
        let dividerXPercentage: CGFloat = isiPad ? (isLandscape ? 3.95 : 5.39) : 5.6
        let weekRangeDividerGapPercentage: CGFloat = isiPad ? (isLandscape ? 0.6 : 0.76) : 1.0
        let dividerX: CGFloat = currentPageRect.width*dividerXPercentage/100.0
        let weekRangeDividerGap: CGFloat = currentPageRect.width*weekRangeDividerGapPercentage/100
        let dividerY: CGFloat = weekRangeYpos + weekRangeString.size().height + weekRangeDividerGap
        let dividerWidth: CGFloat = weekRangeString.size().width

        self.addHorizantalBezierLine(rect: CGRect(x: dividerX, y: dividerY, width: dividerWidth, height: 1.0), toContext: context, withColor: UIColor(hexString: "A2A2A2"))
        
        // Rendering month year string
        let monthXposPercentage: CGFloat = isiPad ? (isLandscape ? 3.95 : 5.39) : 5.6
        let monthXpos: CGFloat = currentPageRect.width*monthXposPercentage/100
        let monthYpos: CGFloat = dividerY + weekRangeDividerGap

        let monthFont = UIFont.robotoRegular(isiPad ? 14 : 12)
        let monthNewFontSize = UIFont.getScaledFontSizeFor(font: monthFont, screenSize: currentPageRect.size, minPointSize: isiPad ? 10 : 8)
        let fullMonthAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.robotoRegular(monthNewFontSize),
                                                        .kern: 0.0,
                                                        .foregroundColor: UIColor.init(hexString:"35383D")]
        let monthString = NSMutableAttributedString.init(string:weeklyInfo.dayInfo[0].fullMonthString.uppercased(), attributes: fullMonthAttrs)
        let monthLocation = CGPoint(x: monthXpos, y: monthYpos)
        monthString.draw(at: monthLocation)
        currentWeekRectInfo.monthRect = getLinkRect(location: monthLocation, frameSize: monthString.size())
        let yearString = NSMutableAttributedString.init(string:weeklyInfo.dayInfo[0].yearString, attributes: fullMonthAttrs)
        let yearXOffset : CGFloat = isiPad ? 12 : 5
        let yearLocation = CGPoint(x: monthXpos + monthString.size().width + yearXOffset , y: monthYpos)
        yearString.draw(at: yearLocation)
        currentWeekRectInfo.yearRect = getLinkRect(location: yearLocation , frameSize: yearString.size())
    }
    
        override func calendarOffsetCount() -> Int {
        return self.offsetCount
    }

    override func renderDayPage(context: CGContext, dayInfo: FTDayInfo) {

        super.renderDayPage(context: context, dayInfo: dayInfo)
        let isLandscape = self.formatInfo.customVariants.isLandscape
        let currentDayRectsInfo: FTDiaryDayRectsInfo = FTDiaryDayRectsInfo()
        // Rendering Day
        let dayXPosPercentage: CGFloat = isiPad ? (isLandscape ? 3.77 : 5.27) : 5.33
        let dayYPosPercentage: CGFloat = isiPad ? (isLandscape ? 4.15 : 3.81) : 2.76
        let dayXpos: CGFloat = currentPageRect.width*dayXPosPercentage/100
        var dayYpos: CGFloat = currentPageRect.height*dayYPosPercentage/100
        if self.customVariants.selectedDevice.identifier == "standard4" ||  self.customVariants.selectedDevice.identifier == "standard2" || (self.customVariants.selectedDevice.identifier == "standard1" && isLandscape) {
            let extraOffset: CGFloat = 10.0
            dayYpos -= extraOffset
        }

        if UIDevice.current.isPhone() && (self.customVariants.selectedDevice.identifier == "standard4" || self.customVariants.selectedDevice.identifier == "standard1" ) {
            let extraOffset: CGFloat = 10.0
            dayYpos -= extraOffset
        }
        
        let dayFont = UIFont.robotoRegular(screenInfo.fontsInfo.dayPageDetails.dayFontSize)
        let minDayFontSize: CGFloat = isiPad ? 35.0 : 20.0
        let dayNewFontSize = UIFont.getScaledFontSizeFor(font: dayFont, screenSize: currentPageRect.size, minPointSize: minDayFontSize)
        let dayAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.robotoRegular(dayNewFontSize),
                                                       .kern: 0.0,
                                                       .foregroundColor: UIColor.init(hexString:"35383D")]
        let dayString = NSMutableAttributedString.init(string: dayInfo.fullDayString, attributes: dayAttrs)
        let dayLocation = CGPoint(x: dayXpos, y: dayYpos)
        dayString.draw(at: dayLocation)
        
        // Rendering month
        let monthXPosPercentage: CGFloat = isiPad ? (isLandscape ? 3.77 : 5.27) : 5.33
        let monthYPosPercentage: CGFloat = isiPad ? (isLandscape ? 12.07 : 10.01) : 7.87
        let monthXpos: CGFloat = currentPageRect.width*monthXPosPercentage/100
        let monthYpos: CGFloat = currentPageRect.height*monthYPosPercentage/100
        
        let monthFont = UIFont.robotoMedium(screenInfo.fontsInfo.dayPageDetails.monthFontSize)
        let minMonthFontSize: CGFloat = isiPad ? 12.0 : 10.0
        let monthNewFontSize = UIFont.getScaledFontSizeFor(font: monthFont, screenSize: currentPageRect.size, minPointSize: minMonthFontSize)
        let monthAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.robotoMedium(monthNewFontSize),
                                                         .kern: 0.72,
                                                         .foregroundColor: UIColor.init(hexString:"35383D")]
        let monthString = NSMutableAttributedString.init(string: dayInfo.fullMonthString.uppercased(), attributes: monthAttrs)
        let monthLocation = CGPoint(x: monthXpos, y: monthYpos)
        monthString.draw(at: monthLocation)
        currentDayRectsInfo.monthRect = getLinkRect(location: monthLocation, frameSize: monthString.size())
        
        // Rendering Week info
        let weekInfoXPosPercentage: CGFloat = isiPad ? (isLandscape ? 3.77 : 5.27) : 5.33
        let weekInfoYPosPercentage: CGFloat = isiPad ? (isLandscape ? 15.32 : 12.78) : 11.18
        let weekInfoXpos: CGFloat = currentPageRect.width*weekInfoXPosPercentage/100
        var weekInfoYpos: CGFloat = currentPageRect.height*weekInfoYPosPercentage/100
        
        if UIDevice.current.isPhone() && ((self.customVariants.selectedDevice.identifier == "standard4") || (self.customVariants.selectedDevice.identifier == "standard1" && !isLandscape)) {
            weekInfoYpos += 10.0
        }

        let weekInfoFont = UIFont.robotoMedium(screenInfo.fontsInfo.dayPageDetails.weekFontSize)
        let minWeekFontSize: CGFloat = isiPad ? 12 : 10
        let weekInfoNewFontSize = UIFont.getScaledFontSizeFor(font: weekInfoFont, screenSize: currentPageRect.size, minPointSize: minWeekFontSize)
        let weekInfoAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.robotoMedium(weekInfoNewFontSize),
                                                            .kern: 0.48,
                                                            .foregroundColor: UIColor.init(hexString:"35383D")]
        let weekRangeAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.robotoMedium(weekInfoNewFontSize),
                                                            .kern: 0.48,
                                                            .foregroundColor: UIColor.init(hexString:"A1A1A1")]
        let weekDayString = NSMutableAttributedString(string: "\(dayInfo.weekString.uppercased())  ", attributes: weekInfoAttrs)
        let weekDayLocation = CGPoint(x: weekInfoXpos, y: weekInfoYpos)
        weekDayString.draw(at: weekDayLocation)
        
        self.drawDot(rect: CGRect(x: weekInfoXpos + weekDayString.size().width, y: weekInfoYpos + weekDayString.size().height/2.0, width: 3.0, height: 3.0), toContext: context, rectBGColor: UIColor.init(hexString:"64645F"), borderColor: .clear, cornerRadius: 1.5)

        let weekInfoString = NSMutableAttributedString.init(string: "  WEEK ", attributes: weekInfoAttrs)
        let weekRangeString = NSMutableAttributedString.init(string: "(\(isiPad ? dayInfo.fullWeekRange.uppercased() : dayInfo.shortWeekRange.uppercased()))", attributes: weekRangeAttrs)
        weekInfoString.append(weekRangeString)
        let weekInfoLocation = CGPoint(x: weekInfoXpos + weekDayString.size().width + 3.0, y: weekInfoYpos)
        currentDayRectsInfo.weekRect = getLinkRect(location: weekInfoLocation, frameSize: weekInfoString.size())
        weekInfoString.draw(at: weekInfoLocation)
        
        // Rendering Quote
        let quoteFont = UIFont.robotoMediumItalic(isiPad ? 14 : 10)
        let quoteNewFontSize = UIFont.getScaledFontSizeFor(font: quoteFont, screenSize: currentPageRect.size, minPointSize: isiPad ? 10 : 8)
        var quoteAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.robotoMediumItalic(quoteNewFontSize),
                                                          NSAttributedString.Key.kern : 0.0,
                                                          .foregroundColor : UIColor.init(hexString: "A1A1A1")];
        
        let style=NSMutableParagraphStyle.init()
        style.alignment = .right
        style.lineBreakMode = .byWordWrapping
        quoteAttrs[.paragraphStyle] = style
        
        let quoteXPercentage: CGFloat = isiPad ? (isLandscape ? 58.90 : 58.63) : 42.66
        let quoteYPercentage: CGFloat = isiPad ? (isLandscape ? 5.45 : 5.24) : 2.90
        let quoteWidthPercentage: CGFloat = isiPad ? (isLandscape ? 37.51 : 36.21) : 51.73
        let quoteX = currentPageRect.width*quoteXPercentage/100
        var quoteY = currentPageRect.height*quoteYPercentage/100
        if self.customVariants.selectedDevice.identifier == "standard4" || self.customVariants.selectedDevice.identifier == "standard2" || (self.customVariants.selectedDevice.identifier == "standard1" && isLandscape ) {
            let extraOffset: CGFloat = 10.0
            quoteY -= extraOffset
        }
        if UIDevice.current.isPhone() && (self.customVariants.selectedDevice.identifier == "standard4" || self.customVariants.selectedDevice.identifier == "standard1" ) {
            let extraOffset: CGFloat = 10.0
            quoteY -= extraOffset
        }

        let quoteRectWidth = currentPageRect.width*quoteWidthPercentage/100
        
        let quote: FTQuoteInfo = quoteProvider.getQutote()
        let quoteString = NSAttributedString.init(string: "\"\(quote.quote)\"", attributes: quoteAttrs)
        let expectedSize:CGSize=quoteString.requiredSizeForAttributedStringConStraint(to: CGSize(width: quoteRectWidth, height: 60))
        quoteString.draw(in: CGRect(x: quoteX, y: quoteY, width: quoteRectWidth, height: expectedSize.height))
        
        let authorFont = UIFont.robotoMediumItalic(isiPad ? 14 : 10)
        let authorNewFontSize = UIFont.getScaledFontSizeFor(font: authorFont, screenSize: currentPageRect.size, minPointSize: isiPad ? 10 : 8)
        let authorAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.robotoMediumItalic(authorNewFontSize),
                                                           NSAttributedString.Key.kern : 0.0,
                                                           .foregroundColor : UIColor.init(hexString: "A1A1A1"),
                                                           .paragraphStyle : style]
        
        let topGapBWQuoteAndAuthorPercentage: CGFloat = isiPad ? (isLandscape ? 0.77 : 0.57) : 0.0
        let topGapBWQuoteAndAuthor: CGFloat = currentPageRect.height*topGapBWQuoteAndAuthorPercentage/100
        let authorString=NSAttributedString.init(string: "- " + quote.author, attributes: authorAttrs);
        let authorY = quoteY + expectedSize.height + topGapBWQuoteAndAuthor
        let authorRect = CGRect(x: quoteX, y: authorY , width: quoteRectWidth, height: 30)
        authorString.draw(in: authorRect)
        
        // Rendering year
        let rightOffsetPercentage: CGFloat = isiPad ? (isLandscape ? 3.57 : 5.15) : 5.52
        let rightOffset: CGFloat = currentPageRect.width*rightOffsetPercentage/100
        let yearXpos: CGFloat = currentPageRect.width - rightOffset
        let yearYPosPercentage: CGFloat = isiPad ? (isLandscape ? 14.41 : 12.21) : 11.18
        var yearYpos: CGFloat = currentPageRect.height*yearYPosPercentage/100
        
        if UIDevice.current.isPhone() && ((self.customVariants.selectedDevice.identifier == "standard4") || (self.customVariants.selectedDevice.identifier == "standard1" && !isLandscape)) {
            yearYpos += 10.0
        }
        
        let yearFont = UIFont.robotoMedium(screenInfo.fontsInfo.dayPageDetails.yearFontSize)
        let yearNewFontSize = UIFont.getScaledFontSizeFor(font: yearFont, screenSize: currentPageRect.size, minPointSize: isiPad ? 12 : 10)
        let yearAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.robotoMedium(yearNewFontSize),
                                                        .kern: 0.72,
                                                        .foregroundColor: UIColor.init(hexString:"35383D")]
        let yearString = NSMutableAttributedString.init(string: dayInfo.yearString, attributes: yearAttrs)
        let yearLocation = CGPoint(x: yearXpos - yearString.size().width, y: yearYpos)
        yearString.draw(at: yearLocation)
        currentDayRectsInfo.yearRect = getLinkRect(location: yearLocation, frameSize: yearString.size())
        dayRectsInfo.append(currentDayRectsInfo)
    }

    func drawDot( rect : CGRect, toContext context : CGContext, rectBGColor : UIColor, borderColor : UIColor, cornerRadius: CGFloat){
        let bezierpath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        bezierpath.lineWidth = 1.0
        context.addPath(bezierpath.cgPath)
        context.saveGState()
        borderColor.setStroke()
        context.strokePath()
        rectBGColor.setFill()
        bezierpath.fill()
        context.translateBy(x: 0, y: CGFloat(currentPageRect.height))
        context.scaleBy(x: 1, y: -1)
        context.restoreGState()
      }

    func addHorizantalBezierLine(rect:CGRect, toContext context : CGContext, withColor color : UIColor) {
        let  bezierLinePath = UIBezierPath()
        let  p0 = CGPoint(x: rect.origin.x, y: rect.origin.y)
        bezierLinePath.move(to: p0)
        let  p1 = CGPoint(x: rect.origin.x + rect.width , y: rect.origin.y)
        bezierLinePath.addLine(to: p1)
        bezierLinePath.lineWidth = 1.0
        bezierLinePath.lineCapStyle = .butt
        color.setStroke()
        context.addPath(bezierLinePath.cgPath)
        bezierLinePath.stroke()
    }

    override func addCalendarLinks(url : URL,format : FTDairyFormat,pageRect: CGRect, calenderYear: FTYearFormatInfo, isToDisplayOutOfMonthDate: Bool,monthlyFormatter : FTYearInfoMonthly, weeklyFormatter : FTYearInfoWeekly) {
        let doc = PDFDocument.init(url: url)
        var pageIndex: Int = 0
        var nextIndex:Int = 0
        let offset = 0
        let atPoint: CGPoint = CGPoint(x: 0, y: pageRect.height)
        let calendar = NSCalendar.gregorian()
        guard let startDate = calendar.date(month: calenderYear.startMonth.month, year: calenderYear.startMonth.year),
              let endFirstDate = calendar.date(month: calenderYear.endMonth.month, year: calenderYear.endMonth.year) else {
                  return
              }
        let endDate = endFirstDate.offsetDate(endFirstDate.numberOfDaysInMonth() - 1)
        nextIndex = 1 
        
        //Linking the year page
        let yearPage = doc?.page(at: pageIndex)
        var yearMonthsCount = 0
        for monthRect in format.yearRectsInfo.monthRects {
            if let page = (doc?.page(at: yearMonthsCount + nextIndex + offset)) {
                yearPage?.addLinkAnnotation(bounds: monthRect, goToPage: page, at: atPoint)
            }
            yearMonthsCount += 1
        }
        pageIndex += 1
        
//        Linking the month pages
        pageIndex = linkModernMonthPages(doc: doc!, index: pageIndex, format: format,
                                             startDate: startDate, endDate: endDate, atPoint: atPoint,monthlyFormatter: monthlyFormatter, weeklyFormatter: weeklyFormatter)
        
        // Linking the week pages
        pageIndex = linkModernWeekPages(_nextIndex: nextIndex, yearMonthsCount: yearMonthsCount, index: pageIndex, doc: doc!, format: format,startDate: startDate, endDate: endDate, atPoint: atPoint,weeklyFormatter: weeklyFormatter)

        //Linking the day pages
        linkModernDayPages(doc: doc!, startDate: startDate, index: pageIndex, format: format, atPoint: atPoint, yearMonthsCount: yearMonthsCount,monthlyFormatter: monthlyFormatter)

        doc?.write(to: url)
    }

    private func linkModernMonthPages(doc: PDFDocument, index: Int, format: FTDairyFormat,
                                  startDate: Date, endDate: Date, atPoint: CGPoint,monthlyFormatter : FTYearInfoMonthly, weeklyFormatter : FTYearInfoWeekly) -> Int {
        var pageIndex = index
        let calendarMonths = monthlyFormatter.monthCalendarInfo
        var monthRectsCount = 0
        
        let lastDate = calendarMonths[calendarMonths.count - 1].dayInfo[calendarMonths[calendarMonths.count - 1].dayInfo.count - 1].date
        
        var daysBeforeCount = 1 + startDate.numberOfMonths(endDate) + calendarMonths[0].dayInfo[0].date.numberOfWeeks(lastDate)
        if endDate.daysBetween(date: lastDate) + 1 > 7 {
            daysBeforeCount -= 1
        }
        self.offsetCount = daysBeforeCount
        
        let startweekDay = startDate.weekDay()
        let weekStartOff = Int(formatInfo.weekFormat)
        var startOffset = 1 - startweekDay
        if(weekStartOff == 2) {
            if startweekDay == 1 {
                startOffset = -6
            }else {
                startOffset = 2 - startweekDay
            }
        }
        
        let weekcalStartDate = startDate.offsetDate(startOffset);
        let weekBeforeDaysCount : Int = 1 + calendarMonths.count
        calendarMonths.forEach { (eachMonth) in
            let monthPage = doc.page(at: pageIndex)
            let monthRectsInfo = format.monthRectsInfo[monthRectsCount]
            if let yearPage = doc.page(at: 0) {
                monthPage?.addLinkAnnotation(bounds: monthRectsInfo.yearRect, goToPage: yearPage, at: atPoint)
            }
            let weekRectsInfo = monthRectsInfo.weekRects
            if !weekRectsInfo.isEmpty {
                for (weekIndex, weekRect) in weekRectsInfo.enumerated() {
                    let numberofWeeks = eachMonth.dayInfo[weekIndex*7].date.numberOfWeeks(weekcalStartDate) - 1
                    let weekPageIndex = weekBeforeDaysCount + numberofWeeks
                    if let page = doc.page(at: weekPageIndex), let lastDate = eachMonth.dayInfo.last?.date ,eachMonth.dayInfo[weekIndex*7].date <  lastDate {
                        monthPage?.addLinkAnnotation(bounds: weekRect, goToPage: page, at: atPoint)
                    }
                    
                }
            }
            var dayRectsCount = 0
            eachMonth.dayInfo.forEach({(eachDay) in
                if isBelongToCalendar(currentDate: eachDay.date, startDate: startDate, endDate: endDate) {
                    if eachDay.belongsToSameMonth {
                        if monthRectsInfo.dayRects.count > dayRectsCount {
                            let dayIndex = eachDay.date.daysBetween(date: startDate) + daysBeforeCount
                            if let page = doc.page(at: dayIndex) {
                                monthPage?.addLinkAnnotation(bounds: monthRectsInfo.dayRects[dayRectsCount], goToPage: page, at: atPoint)
                            }
                        }
                        dayRectsCount += 1
                    }
                }
            })
            pageIndex += 1
            monthRectsCount += 1
        }
        return pageIndex
    }
    
    private func linkModernWeekPages(_nextIndex: Int, yearMonthsCount: Int, index: Int, doc: PDFDocument, format:FTDairyFormat,
                                 startDate: Date, endDate: Date, atPoint: CGPoint, weeklyFormatter : FTYearInfoWeekly) -> Int {
        var pageIndex = index
        var nextIndex = _nextIndex
        nextIndex = 1 + yearMonthsCount + weeklyFormatter.weeklyInfo.count
        let weeklyInfo = weeklyFormatter.weeklyInfo;
        var weekRectsCount = 0
        weeklyInfo.forEach { (weekInfo) in
            let weekPage = doc.page(at: pageIndex);
            let weekRectsInfo:FTDiaryWeekRectsInfo = format.weekRectsInfo[weekRectsCount]
            
            let monthTo:Int = startDate.numberOfMonths(weekInfo.dayInfo[0].date) - 1
            
            if isBelongToCalendar(currentDate: weekInfo.dayInfo[0].date, startDate: startDate, endDate: endDate){
                weekPage?.addLinkAnnotation(bounds: weekRectsInfo.monthRect, goToPage: (doc.page(at: 1 + monthTo))!, at : atPoint)
            }
            weekPage?.addLinkAnnotation(bounds: weekRectsInfo.yearRect, goToPage: (doc.page(at: 0))!, at : atPoint)
            var currentWeekDaysCount=0
            for weekDayRect in weekRectsInfo.weekDayRects{
                if let page = (doc.page(at: currentWeekDaysCount + nextIndex)) {
                    weekPage?.addLinkAnnotation(bounds: weekDayRect, goToPage: page, at : atPoint)
                }
                currentWeekDaysCount+=1
            }
            nextIndex += currentWeekDaysCount
            
            pageIndex += 1
            weekRectsCount += 1
        }
        return pageIndex
    }
    private func linkModernDayPages(doc: PDFDocument, startDate: Date, index: Int, format: FTDairyFormat, atPoint: CGPoint, yearMonthsCount: Int,monthlyFormatter : FTYearInfoMonthly) {
        var pageIndex = index
        let monthInfo = monthlyFormatter.monthCalendarInfo;
        var dayRectsCount = 0
        
        let startweekDay = startDate.weekDay();
        let weekStartOff = Int(formatInfo.weekFormat);
        var startOffset = 1 - startweekDay
        if(weekStartOff == 2) {
            if startweekDay == 1 {
                startOffset = -6
            }else {
                startOffset = 2 - startweekDay
            }
        }
        
        let weekcalStartDate = startDate.offsetDate(startOffset);
        
        var helperOffset = startDate.weekDay() - 1
        monthInfo.forEach { (eachMonth) in
            let dayInfo = eachMonth.dayInfo;
            dayInfo.forEach { (eachDayInfo) in
                if eachDayInfo.belongsToSameMonth{
                    let dayPage = doc.page(at: pageIndex);
                    let dayRectsInfo:FTDiaryDayRectsInfo=format.dayRectsInfo[dayRectsCount]
                    
                    var monthTo:Int=eachDayInfo.month
                    let year:Int=eachDayInfo.year
                    
                    if monthTo == formatInfo.startMonth.month && year == formatInfo.startMonth.year {
                        monthTo = 0
                    } else if monthTo == formatInfo.endMonth.month && year == formatInfo.endMonth.year {
                        monthTo = 13
                    }
                    
                    let monthPage = eachDayInfo.date.numberOfMonths(startDate);
                    if let page = doc.page(at: monthPage) {
                        dayPage?.addLinkAnnotation(bounds: dayRectsInfo.monthRect, goToPage:  page, at : atPoint)
                    }
                    
                    let weekPage = eachDayInfo.date.numberOfWeeks(weekcalStartDate) - 1;
                    if let page = doc.page(at: 1 + yearMonthsCount + weekPage) {
                        dayPage?.addLinkAnnotation(bounds: dayRectsInfo.weekRect, goToPage:  page, at : atPoint)
                    }
                    
                    dayPage?.addLinkAnnotation(bounds: dayRectsInfo.yearRect, goToPage: (doc.page(at: 0))!, at : atPoint)
                    
                    pageIndex += 1
                    dayRectsCount += 1
                }
            }
        }
    }

}
