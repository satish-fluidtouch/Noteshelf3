//
//  FTDiaryFormatIphonePort.swift
//  Template Generator
//
//  Created by sreenu cheedella on 01/12/19.
//  Copyright © 2019 Amar. All rights reserved.
//

import UIKit
import PDFKit
import FTStyles

class FTDiaryFormatIphonePort: FTDairyFormat {
    override func renderMonthPage(context: CGContext, monthInfo: FTMonthlyCalendarInfo, calendarYear: FTYearFormatInfo) {
        super.renderMonthPage(context: context, monthInfo: monthInfo, calendarYear: calendarYear)
        
        self.renderMonthTitle(monthInfo: monthInfo);
        
        render(dayInfo: monthInfo.dayInfo, calendarYear: calendarYear)
    }
    
    override func renderYearPage(context: CGContext,
                                 months : [FTMonthInfo],
                                 calendarYear : FTYearFormatInfo) {
        super.renderYearPage(context: context,
                             months: months,
                             calendarYear : calendarYear);
        let templateInfo = screenInfo.spacesInfo.yearPageSpacesInfo
        let pageRect = UIGraphicsGetPDFContextBounds();
        
        let baseBoxX = templateInfo.baseBoxX
        let baseBoxY = templateInfo.baseBoxY
        let yearX = baseBoxX ;
        let yearY = baseBoxY - 45.5 - 90;
        
        let attrs : [NSAttributedString.Key : Any] =  [.font : UIFont.appFont(for: .light, with: 75.7),
                                                      NSAttributedString.Key.kern : -3.91,
                                                      .foregroundColor : UIColor.charcoalGrey];
        
        let monthAttr = NSMutableAttributedString.init(string: calendarPageYear,
            attributes:attrs);
        monthAttr.draw(at: CGPoint.init(x: yearX, y: yearY));
        yearRectsInfo.yearRect = CGRect(x: yearX, y:pageRect.size.height - yearY - monthAttr.size().height, width: monthAttr.size().width, height: monthAttr.size().height)
        
        var curMonthIndex : CGFloat  = 1;
        let offsetPointx : CGFloat = 6.1;
        let offsetPointy : CGFloat = 5.8;
        
        let monthStartX : CGFloat = baseBoxX
        let monthStartY : CGFloat = baseBoxY;
        let monthSpcaingX : CGFloat  = templateInfo.cellOffsetX
        let monthSpcaingY : CGFloat  = templateInfo.cellOffsetY
        let boxBottomOffset : CGFloat  = templateInfo.boxBottomOffset
        
        let monthCellWidth : CGFloat  = (pageRect.size.width - (2*(baseBoxX+monthSpcaingX)))/3 ;
        let monthCellHeight : CGFloat  = (pageRect.size.height - baseBoxY - boxBottomOffset - (3*monthSpcaingY))/4;
        
        var renderX = monthStartX;
        var renderY = monthStartY;
        
        months.forEach { (month) in
            let attrs : [NSAttributedString.Key : Any] =  [.font : UIFont.appFont(for: .medium, with: 12),
                                                           NSAttributedString.Key.kern : -1,
                                                           .foregroundColor : UIColor.charcoalGrey];
            let monthAttr = NSMutableAttributedString.init(string: month.monthTitle,
                                                           attributes:attrs);
            
            let x = renderX + offsetPointx;
            let y = renderY + offsetPointy;
            
            monthAttr.draw(at: CGPoint.init(x: x, y: y));
            yearRectsInfo.monthRects.append(CGRect(x: renderX, y: pageRect.height - renderY - monthCellHeight,
                                                   width: monthCellWidth, height: monthCellHeight))
            curMonthIndex += 1;
            if(curMonthIndex > 3) {
                curMonthIndex = 1;
                renderX = monthStartX;
                renderY += (monthCellHeight + monthSpcaingY)
            }
            else {
                renderX += (monthCellWidth + monthSpcaingX)
            }
        }
    }
    
    override func renderDayPage(context: CGContext, dayInfo: FTDayInfo) {
        if !dayInfo.belongsToSameMonth {
            return
        }
        super.renderDayPage(context: context, dayInfo: dayInfo);
        let currentDayRectsInfo:FTDiaryDayRectsInfo=FTDiaryDayRectsInfo()
        let pageRect = UIGraphicsGetPDFContextBounds();
        let templateInfo = screenInfo.spacesInfo.dayPageSpacesInfo
        let baseX = templateInfo.baseX
        let baseY = templateInfo.baseY
        
        var quoteAttrs:[NSAttributedString.Key:Any]=[NSAttributedString.Key.font:UIFont.appFont(for: .medium, with: 10, trait: .traitItalic),
//                                                    NSAttributedString.Key.foregroundColor: UIColor.black.withAlphaComponent(0.5),
                                                    NSAttributedString.Key.foregroundColor: UIColor.black.withAlphaComponent(0.5),
                                                    NSAttributedString.Key.kern:0]
        //Drawing the quote data
        let quote:FTQuoteInfo = quoteProvider.getQutote()
        
        let style=NSMutableParagraphStyle.init()
        style.alignment=NSTextAlignment.right
        quoteAttrs[.paragraphStyle] = style
        
        let quoteString=NSAttributedString.init(string: "\""+quote.quote+"\"", attributes: quoteAttrs);
        
        let quoteWidth:CGFloat=260
        let quoteX:CGFloat=pageRect.width-(quoteWidth) - baseX - 7
        let quoteY:CGFloat=30
        let expectedSize:CGSize=quoteString.requiredSizeForAttributedStringConStraint(to: CGSize(width: quoteWidth, height: 250))
        let quoteHeight:CGFloat=expectedSize.height
        
        quoteString.draw(in: CGRect(x: quoteX, y: quoteY, width: quoteWidth, height: quoteHeight))
        
        let quoteAuthorString = NSAttributedString.init(string: "- " + quote.author, attributes: quoteAttrs)
        quoteAuthorString.draw(at: CGPoint(x: pageRect.width - baseX - quoteAuthorString.size().width - 7, y: quoteY+quoteHeight+7))
        
        var x : CGFloat = baseX + 7;
        var y : CGFloat = baseY;
        
        var attrs : [NSAttributedString.Key : Any] =  [.font : UIFont.appFont(for: .regular, with: 48),
                                                      NSAttributedString.Key.kern : 0,
                                                      .foregroundColor : UIColor.black.withAlphaComponent(0.8)];
        
        let dayStr = NSAttributedString.init(string: dayInfo.dayString, attributes: attrs);
        dayStr.draw(at: CGPoint.init(x: x, y: y));
        
        y += dayStr.size().height-9;
        attrs[.font] = UIFont.appFont(for: .bold, with: 16)
        let monthString = NSAttributedString.init(string: dayInfo.fullMonthString.uppercased(), attributes: attrs);
        
        x-=7
        let monthFrame:CGRect=CGRect(x: x, y: y, width: monthString.size().width+15, height: monthString.size().height+15)
        monthString.draw(at: CGPoint.init(x: x+7, y: y+8));
        context.setFillColor(UIColor(red: 130/255.0, green: 91/255.0, blue: 225/255.0, alpha: 0.5).cgColor)
//        context.fill(monthFrame)
        currentDayRectsInfo.monthRect=CGRect(x: x, y: pageRect.height - y - monthFrame.height, width: monthFrame.width, height: monthFrame.height)
        
        y += monthFrame.height;
        attrs[.font] = UIFont.appFont(for: .bold, with: 11)
        let weekDayString = NSAttributedString.init(string: dayInfo.weekString.uppercased(), attributes: attrs);
        
        let weekFrame:CGRect=CGRect(x: x, y: y, width: weekDayString.size().width+10, height: weekDayString.size().height+16)
        weekDayString.draw(at: CGPoint.init(x: x+7, y: y+7));
        context.setFillColor(UIColor(red: 243/255.0, green: 84/255.0, blue: 73/255.0, alpha: 0.5).cgColor)
//        context.fill(weekFrame)
        currentDayRectsInfo.weekRect=CGRect(x: x, y: pageRect.height - y - weekFrame.height, width: weekFrame.width, height: weekFrame.height)
        
        attrs[.foregroundColor] = UIColor.black;
        let yearString = NSAttributedString.init(string: dayInfo.yearString, attributes: attrs);
        
        x = pageRect.width - yearString.size().width - 30 - baseX
        let yearFrame = CGRect(x: x, y: y, width: yearString.size().width + 30, height: yearString.size().height+16)
        
        yearString.draw(at: CGPoint.init(x: x+14, y: y+8));
        context.setFillColor(UIColor(red: 180/255.0, green: 237/255.0, blue: 16/255.0, alpha: 0.5).cgColor)
//        context.fill(yearFrame)
        currentDayRectsInfo.yearRect=CGRect(x: x, y: pageRect.height - y - yearFrame.height, width: yearFrame.width, height: yearFrame.height)
        dayRectsInfo.append(currentDayRectsInfo)
    }
    
    override func renderWeekPage(context: CGContext, weeklyInfo: FTWeekInfo) {
        super.renderWeekPage(context: context, weeklyInfo: weeklyInfo);
        let currentWeekRectInfo:FTDiaryWeekRectsInfo = FTDiaryWeekRectsInfo()
        let pageRect = UIGraphicsGetPDFContextBounds();
        let dayInfos = weeklyInfo.dayInfo;
        let templateInfo = screenInfo.spacesInfo.weekPageSpacesInfo
        let baseBoxX:CGFloat=templateInfo.baseBoxX
        let baseBoxY:CGFloat=templateInfo.baseBoxY
        let titleLineY:CGFloat=templateInfo.titleLineY
        
        let fromToDateAttrs:[NSAttributedString.Key:Any]=[NSAttributedString.Key.font:UIFont.appFont(for: .bold, with: 10),
                                                         NSAttributedString.Key.foregroundColor: UIColor.black.withAlphaComponent(0.2),
                                                         NSAttributedString.Key.kern:0]
        //Drawing the Date data
        var dateString:String;
        let firstDay:FTDayInfo =  dayInfos[0]
        let lastDay:FTDayInfo = dayInfos[dayInfos.count-1]
        if firstDay.yearString.elementsEqual(lastDay.yearString){
            dateString=firstDay.dayString+" "+firstDay.monthString+" - "+lastDay.dayString+" "+lastDay.monthString
        }else{
            dateString=firstDay.dayString+" "+firstDay.monthString+" "+firstDay.yearString+" - "+lastDay.dayString+" "+lastDay.monthString+" "+lastDay.yearString
        }
        let fromToDateString=NSAttributedString.init(string: dateString,attributes: fromToDateAttrs)
        let dateX:CGFloat=baseBoxX
        fromToDateString.draw(at: CGPoint(x: dateX, y: titleLineY - 8 - fromToDateString.size().height))
        
        let headAttrs : [NSAttributedString.Key:Any] = [NSAttributedString.Key.font:UIFont.appFont(for: .bold, with: 12),
                                                       NSAttributedString.Key.foregroundColor: UIColor.black.withAlphaComponent(0.5),
                                                       NSAttributedString.Key.kern:0];
        //Drawing the month data
        let monthString=NSAttributedString.init(string: dayInfos[0].fullMonthString.uppercased(), attributes: headAttrs);
        
        let monthFrameX:CGFloat=baseBoxX-6;
        let monthFrameY:CGFloat=titleLineY;
        let monthFrameWidth:CGFloat=monthString.size().width+12;
        let monthFrameHeight:CGFloat=monthString.size().height+14;
        let monthFrame:CGRect=CGRect(x: monthFrameX, y: monthFrameY, width: monthFrameWidth, height: monthFrameHeight);
        //        let bpath:UIBezierPath = UIBezierPath(rect: frame);
        //        let color:UIColor=UIColor(red: 130/255.0, green: 91/255.0, blue: 225/255.0, alpha: 0.5)
        //        color.set();
        //        bpath.fill();
        context.setFillColor(UIColor(red: 130/255.0, green: 91/255.0, blue: 225/255.0, alpha: 0.5).cgColor)
//        context.fill(monthFrame)
        monthString.draw(at: CGPoint(x: monthFrameX+6, y: monthFrameY+7));
        currentWeekRectInfo.monthRect=CGRect(x: monthFrameX, y: pageRect.height - monthFrameY - monthFrameHeight,
                                             width: monthFrameWidth, height: monthFrameHeight)
        
        //Drawing the year data
        let yearString=NSAttributedString.init(string: dayInfos[0].yearString, attributes: headAttrs);
        
        let yearFrameX=monthFrameX+monthFrameWidth
        let yearFrameY=monthFrameY
        let yearFrameWidth=yearString.size().width+12
        let yearFrameHeight=monthFrameHeight
        
        let yearFrame:CGRect=CGRect(x: yearFrameX, y: yearFrameY, width: yearFrameWidth, height: yearFrameHeight)
        context.setFillColor(UIColor(red: 180/255, green: 237/255, blue: 16/255, alpha: 0.5).cgColor)
//        context.fill(yearFrame)
        yearString.draw(at: CGPoint(x: yearFrameX+6, y: yearFrameY+7))
        currentWeekRectInfo.yearRect=CGRect(x: yearFrameX, y: pageRect.height - yearFrameY - yearFrameHeight,
                                            width: yearFrameWidth, height: yearFrameHeight)
        
        //Drawing week data
        let x:CGFloat=baseBoxX
        let y:CGFloat=baseBoxY
        let cellOffset:CGFloat=templateInfo.cellOffsetX
        let weekParentOffset:CGFloat=12
        let cellWidth:CGFloat=(pageRect.width - (2*x) - (1*cellOffset)) / 2
        let cellHeight:CGFloat = templateInfo.cellHeight
        let lastCellHeight:CGFloat = templateInfo.lastCellHeight
        
        var index:CGFloat=0
        for day in dayInfos {
            let weekString=NSAttributedString.init(string: day.weekString.uppercased(),attributes: headAttrs)
            let widthFactor=index.truncatingRemainder(dividingBy: 2)
            let heightFactor:CGFloat=index/2
            let weekFrameX:CGFloat=x+(widthFactor*(cellWidth+cellOffset))
            let weekFrameY:CGFloat=y+((cellHeight+cellOffset)*heightFactor.rounded(.down))
            weekString.draw(at: CGPoint(x: weekFrameX+weekParentOffset, y:weekFrameY+weekParentOffset ))
            
            let calendar = NSCalendar.gregorian()
            let startDate = calendar.date(month: formatInfo.startMonth.month, year: formatInfo.startMonth.year)
            let endDateFirst = calendar.date(month: formatInfo.endMonth.month, year: formatInfo.endMonth.year)
            let daysInMonth = endDateFirst?.numberOfDaysInMonth() ?? 1;
            let endDate = calendar.date(month: (endDateFirst?.month())!,
                                        year: (endDateFirst?.year())!,
                                        day: daysInMonth);
            
            if day.date >= startDate! && day.date <= endDate! {
//            if index<6{
//                currentWeekRectInfo.weekDayRects.append(CGRect(x: weekFrameX, y: pageRect.height - weekFrameY - cellHeight, width: cellWidth, height: cellHeight))
//            }else{
//                currentWeekRectInfo.weekDayRects.append(CGRect(x: weekFrameX, y: pageRect.height - weekFrameY - lastCellHeight , width: pageRect.width - (2*baseBoxX), height: lastCellHeight))
//            }
                currentWeekRectInfo.weekDayRects.append(CGRect(x: weekFrameX, y: pageRect.height - weekFrameY - (2*weekParentOffset + weekString.size().height),
                                                               width: 2*weekParentOffset + weekString.size().width, height: 2*weekParentOffset + weekString.size().height))
            }
            index+=1
        }
        weekRectsInfo.append(currentWeekRectInfo)
    }
    
    override func renderYearPageTitle(monthInfo: FTMonthlyCalendarInfo) {
        var attrs : [NSAttributedString.Key : Any] =  [.font : UIFont.appFont(for: .light, with: 155),
                                                      NSAttributedString.Key.kern : -8,
                                                      .foregroundColor : UIColor.charcoalGrey];
        
        let monthAttr = NSMutableAttributedString.init(string: monthInfo.shortMonth.appending(" "),
                                                       attributes:attrs);
        
        attrs[.font] = UIFont.appFont(for: .light, with: 48)
        attrs[.kern] = -2;
        attrs[.foregroundColor] = UIColor.color7f7f7f
        
        let yearAttr = NSMutableAttributedString.init(string: monthInfo.year, attributes:attrs)
        
        monthAttr.append(yearAttr);
        monthAttr.draw(at: CGPoint.init(x: 44, y: 67));
        
    }
    
    override func renderMonthTitle(monthInfo: FTMonthlyCalendarInfo) {
        let currentMonthRectsInfo:FTDiaryMonthRectsInfo=FTDiaryMonthRectsInfo()
        let templateInfo = screenInfo.spacesInfo.monthPageSpacesInfo
        let pageRect = UIGraphicsGetPDFContextBounds();
        let baseBoxX:CGFloat=templateInfo.baseBoxX
        let baseBoxY:CGFloat=templateInfo.baseBoxY
        
        var attrs : [NSAttributedString.Key : Any] =  [.font : UIFont.appFont(for: .light, with: 75.7),
                                                      NSAttributedString.Key.kern : -3.91,
                                                      .foregroundColor : UIColor.charcoalGrey];
        
        let monthAttr = NSMutableAttributedString.init(string: monthInfo.shortMonth.uppercased().appending(" "),
                                                       attributes:attrs);
        
        let monthX:CGFloat = baseBoxX
        let monthY:CGFloat = baseBoxY - 78.2 - monthAttr.size().height
        currentMonthRectsInfo.monthRect=CGRect(x: monthX, y: pageRect.height - monthY - monthAttr.size().height,
                                               width: monthAttr.size().width, height: monthAttr.size().height)
        
        attrs[.font] = UIFont.appFont(for: .light, with: 23.4)
        attrs[.kern] = -0.98;
        attrs[.foregroundColor] = UIColor.color7f7f7f
        
        let yearAttr = NSMutableAttributedString.init(string: monthInfo.year, attributes:attrs)
        
        let yearX:CGFloat = monthX + monthAttr.size().width
        let yearY:CGFloat = monthY + monthAttr.size().height - yearAttr.size().height - 12.4
        currentMonthRectsInfo.yearRect=CGRect(x: yearX, y: pageRect.height - yearY - yearAttr.size().height, width: yearAttr.size().width, height: yearAttr.size().height)
        
        monthAttr.append(yearAttr);
        monthAttr.draw(at: CGPoint.init(x:baseBoxX, y:  baseBoxY - 78.2 - monthAttr.size().height));
        
        let dateFormatter = DateFormatter.init();
        dateFormatter.locale = Locale.init(identifier: monthInfo.localeID);
        var symbols = dateFormatter.veryShortWeekdaySymbols;
        
        let cellWidth = (pageRect.width - (2*baseBoxX - 1))/7
        
        let localAttrs : [NSAttributedString.Key : Any] =  [.font :UIFont.appFont(for: .medium, with: 12),
                                                           NSAttributedString.Key.kern : 0.0,
                                                           .foregroundColor : UIColor.color7f7f7f];
        let symbol:NSAttributedString = NSAttributedString.init(string: (symbols?[0])!, attributes: localAttrs)
        var startX = baseBoxX + 4.9;
        let startY = baseBoxY - 6.5 - symbol.size().height;
        
        if self.formatInfo.weekFormat.elementsEqual("2"){
            let first = symbols?[0]
            symbols?.remove(at: 0)
            symbols?.append((first)!)
        }
        
        symbols?.forEach({ (eachSym) in
            let sym = NSAttributedString.init(string: eachSym, attributes: localAttrs)
            sym.draw(at: CGPoint(x: startX, y: startY));
            startX += cellWidth;
        });
        monthRectsInfo.append(currentMonthRectsInfo)
    }
    
    override func render(dayInfo : [FTDayInfo], calendarYear: FTYearFormatInfo)
    {
        let currentMonthRectsInfo:FTDiaryMonthRectsInfo=monthRectsInfo[monthRectsInfo.count-1]
        let templateInfo = screenInfo.spacesInfo.monthPageSpacesInfo
        let pageRect = UIGraphicsGetPDFContextBounds();
        let baseBoxX:CGFloat=templateInfo.baseBoxX
        let baseBoxY:CGFloat=templateInfo.baseBoxY
        let boxBottomOffset:CGFloat=templateInfo.boxBottomOffset
        
        var attrs : [NSAttributedString.Key : Any] =  [.font :UIFont.appFont(for: .medium, with: 12),
                                                      NSAttributedString.Key.kern : -1.0];
        
        let startX = baseBoxX;
        let startY = baseBoxY;
        let cellWidth =  (pageRect.width - (2*baseBoxX + 1))/7
        let cellHeigth = (pageRect.height - baseBoxY - boxBottomOffset)/6;
        
        let cellOffsetX: CGFloat = 4.9
        let cellOffsetY:CGFloat = 3.1
        
        var index = 1;
        
        var x = startX;
        var y = startY;
        
        dayInfo.forEach { (eachDay) in
            let frame = CGRect.init(x: x + cellOffsetX,
                                    y: y+cellOffsetY,
                                    width: cellWidth,
                                    height: cellHeigth);
            
            if(eachDay.belongsToSameMonth) {
                attrs[.foregroundColor] = UIColor.charcoalGrey;
            }
            else {
                attrs[.foregroundColor] = UIColor.charcoalGrey20Alpha;
            }
            
            let attr = NSAttributedString.init(string: eachDay.dayString,
                                               attributes: attrs);
            attr.draw(in: frame)
            if isBelongToCalendarYear(currentDate: eachDay.date) {
                let minLength = CGFloat(30)
                let rectWidth = 2*cellOffsetX + attr.size().width
                let rectHeight = 2*cellOffsetY + attr.size().height
                currentMonthRectsInfo.dayRects.append(CGRect(x: x, y: pageRect.height - y - (rectHeight >= minLength ? rectHeight : minLength),
                                                             width: rectWidth >= minLength ? rectWidth : minLength,
                                                             height: rectHeight >= minLength ? rectHeight : minLength))
            }
            
            index += 1;
            if(index > 7) {
                index = 1;
                x = startX;
                y += cellHeigth;
            }
            else {
                x += cellWidth;
            }
        };
    }
}
