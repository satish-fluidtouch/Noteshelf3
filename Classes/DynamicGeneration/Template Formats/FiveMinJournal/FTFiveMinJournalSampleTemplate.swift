//
//  FTFiveMinJournalSampleTemplate.swift
//  Noteshelf
//
//  Created by Ramakrishna on 06/08/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTFiveMinJournalSampleTemplate : FTFiveMinJournalTemplateFormat {
    
    let dayPageHeadings : [String] = ["My affirmations for the day","Today I will accomplish","I am thankful for","Three things that made me happy today","Today I learnt"]
    let sampleAnswersForQuestion1InPort = ["  \u{2022}  I am Worthy","  \u{2022}  I am loved and appreciated","  \u{2022}  I am good at what I do"]
    let sampleAnswersForQuestion1InLand = [" \u{2022}  I am Worthy"," \u{2022}  I am loved and appreciated"]
    let sampleAnswersForQuestion2iPadPort = ["  \u{2022}  One act of kindness","  \u{2022}  One task that is difficult- cook a full meal","  \u{2022}  One task that I like the least- presentation at work"]
    let sampleAnswersForQuestion2iPadLand = [" \u{2022}  One act of kindness"," \u{2022}  One task that is difficult- cook a full meal"]
    let sampleAnswersForQuestion3InPort = ["  \u{2022}  My friends, family and their support","  \u{2022}  Amy, and how she makes it so easy to hang out with her","  \u{2022}  This life and the ability to walk and enjoy nature"]
    let sampleAnswersForQuestion3InLand = [" \u{2022}  My friends, family and their support"," \u{2022}  Amy, and how she makes it so easy to hang out with her"]
    let sampleAnswersForQuestion4InPort = ["  \u{2022}  Got an A on my French test","  \u{2022}  A dog played with me in the park","  \u{2022}  Appreciated by colleagues at work"]
    let sampleAnswersForQuestion4InLand = [" \u{2022}  Got an A on my French test"," \u{2022}  A dog played with me in the park","\u{2022}  Appreciated by colleagues at work"]
    let sampleAnswersForQuestion5IniPadPort = ["  \u{2022}  Sometimes doing the things I dislike can also make me happy."]
    let sampleAnswersForQuestion5IniPadLand = [" \u{2022}  Sometimes doing the things I dislike can also make me happy."]
    let quote = "The place to be happy is here. The time to be happy is now."
    let author = "Robert G. Ingersoll"
    
    let sampleAnswersForQuestion1iPhonePort = ["  \u{2022}  I am Worthy","  \u{2022}  I am loved and appreciated"]
    let sampleAnswersForQuestion1iPhoneLand = ["   \u{2022}  I am Worthy","   \u{2022}  I am loved and appreciated"]
    let sampleAnswersForQuestion2iPhone = ["  \u{2022}  One act of kindness","  \u{2022}  One task that is difficult- cook a full meal"]
    let sampleAnswersForQuestion2iPhoneLand = ["   \u{2022}  One act of kindness","   \u{2022}  One task that is difficult- cook a full meal"]
    let sampleAnswersForQuestion3InPortiPhone = ["  \u{2022}  My friends, family and their support","  \u{2022}  Amy, and how easy it is to talk to her"]
    let sampleAnswersForQuestion3InLandiPhone = ["   \u{2022}  My friends, family and their support","   \u{2022}  Amy, and how easy it is to talk to her"]
    
    let sampleAnswersForQuestion4InPortiPhone = ["  \u{2022}  Got an A on my French test","  \u{2022}  A dog played with me in the park"]
    let sampleAnswersForQuestion4InLandiPhone = ["    \u{2022}  Got an A on my French test","    \u{2022}  A dog played with me in the park"]
    let sampleAnswersForQuestion5iPhoneport = ["  \u{2022}  Sometimes doing the things I dislike can also ","  make me happy."]
    let sampleAnswersForQuestion5iPhoneLand = ["    \u{2022}  Sometimes doing the things I dislike can also ","    make me happy."]
    
    var quoteX : CGFloat = 0.0
    var quoteY : CGFloat = 0.0
    var quoteWidth : CGFloat = 0.0
    var headingWidth : CGFloat = 0.0
    var headingX : CGFloat = 0.0
    var heading1Y : CGFloat = 0.0
    var heading2Y : CGFloat = 0.0
    var heading3Y : CGFloat = 0.0
    var heading4Y : CGFloat = 0.0
    var heading5Y : CGFloat = 0.0
    var yearX : CGFloat = 0.0
    var yearY : CGFloat = 0.0
    
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        if templateInfo.customVariants.selectedDevice.isiPad {
            self.renderiPadTemplate(context: context)
        }
        else {
            self.renderiPhoneTemplate(context: context)
        }
    }
    private func renderiPadTemplate(context : CGContext){
        if let templateInfo = self.templateInfo as? FTFiveMinJournalTemplateInfo {
            let dayTemplateOBJ = FTFiveMinJournalDayTemplate(templateInfo: templateInfo)
            
            let isLandscape = self.templateInfo.customVariants.isLandscape
            // Rendering sample logo
            
            let logoXPercntage : CGFloat = isLandscape ? 75.64 : 67.82
            let logoYPercntage : CGFloat = isLandscape ? 4.45 : 3.43
            let logoWidthPercntage : CGFloat = isLandscape ? 22.61 : 30.15
            
            let logoXValue = templateInfo.screenSize.width*logoXPercntage/100
            let logoYValue = templateInfo.screenSize.height*logoYPercntage/100
            let logoWidthValue = templateInfo.screenSize.width*logoWidthPercntage/100
            
            let sampleEntryImage = UIImage(named: "samplePageSampleLogo")
            let sampleEntryRect = CGRect(x: logoXValue, y: logoYValue, width: logoWidthValue, height: logoWidthValue)
            sampleEntryImage?.draw(in: sampleEntryRect)

            dayTemplateOBJ.renderiPadTemplate(context: context)
            
            let qustn1WrtngAreaDashedLinesY : CGFloat =  templateInfo.customVariants.isLandscape ? 24.61 : 26.81
            let WrtngAreaDashedLinesX : CGFloat = templateInfo.customVariants.isLandscape ? 4.85 : 6.11
            let qustn2WrtngAreaDashedLinesY : CGFloat = templateInfo.customVariants.isLandscape ? 38.53 : 40.83
            let qustn3WrtngAreaDashedLinesY : CGFloat = templateInfo.customVariants.isLandscape ? 52.30 : 54.86
            let qustn4WrtngAreaDashedLinesY : CGFloat = templateInfo.customVariants.isLandscape ? 70.49 : 73.66
            let qustn5WrtngAreaDashedLinesY : CGFloat = templateInfo.customVariants.isLandscape ? 88.50 : 87.69
            let dashedLinesVerticalGapY : CGFloat = templateInfo.customVariants.isLandscape ? 4.15 : 3.24
            
            let dashedLinesVerticalGapValue = templateInfo.screenSize.height*CGFloat(dashedLinesVerticalGapY)/100
            let dashedLiensXAxis = templateInfo.screenSize.width*CGFloat(WrtngAreaDashedLinesX)/100
            
            var answersMinimumFontSize : CGFloat = 20
            var answersFont = UIFont.dancingScriptRegular(20)
            if self.templateInfo.customVariants.selectedDevice.identifier == "standard1" {
                answersFont = UIFont.dancingScriptRegular(16)
                answersMinimumFontSize = 16
            }
            let answersNewFontSize = UIFont.getScaledFontSizeFor(font: answersFont, screenSize: self.templateInfo.screenSize, minPointSize: answersMinimumFontSize)
            
            let answerAttr  = [
                NSAttributedString.Key.font: UIFont.dancingScriptRegular(answersNewFontSize),
                NSAttributedString.Key.foregroundColor: UIColor.init(hexString: "#06438B"),
                NSAttributedString.Key.kern : 0.0] as [NSAttributedString.Key : Any]
            
            let answersX = isLandscape ? templateInfo.screenSize.width*CGFloat(1.73)/100 : templateInfo.screenSize.width*CGFloat(6.59)/100
            let answersY = isLandscape ? templateInfo.screenSize.height*CGFloat(3.31)/100 :templateInfo.screenSize.height*CGFloat(2.29)/100
            // question1 answers
            var qustn1WrtngAreaYAxis = templateInfo.screenSize.height*CGFloat(qustn1WrtngAreaDashedLinesY)/100
            let questions1Answers = isLandscape ? sampleAnswersForQuestion1InLand : sampleAnswersForQuestion1InPort
            for ans in questions1Answers {
                let answerString = NSAttributedString(string: ans, attributes: answerAttr)
                let answerRect = CGRect(x: dashedLiensXAxis, y: qustn1WrtngAreaYAxis - answersY + 2, width: answerString.size().width, height: answerString.size().height)
                answerString.draw(in: answerRect)
                qustn1WrtngAreaYAxis += dashedLinesVerticalGapValue
            }
            
            //question2 answers
            var qustn2WrtngAreaYAxis = templateInfo.screenSize.height*CGFloat(qustn2WrtngAreaDashedLinesY)/100
            let sampleAnswersForQuestion2 = isLandscape ? sampleAnswersForQuestion2iPadLand : sampleAnswersForQuestion2iPadPort
            for ans in sampleAnswersForQuestion2 {
                let answerString = NSAttributedString(string: ans, attributes: answerAttr)
                let answerRect = CGRect(x: dashedLiensXAxis , y: qustn2WrtngAreaYAxis - answersY + 2, width: answerString.size().width, height: answerString.size().height)
                answerString.draw(in: answerRect)
                qustn2WrtngAreaYAxis += dashedLinesVerticalGapValue
            }
            //question3 answers
            var qustn3WrtngAreaYAxis = templateInfo.screenSize.height*CGFloat(qustn3WrtngAreaDashedLinesY)/100
            let questions3Answers = isLandscape ? sampleAnswersForQuestion3InLand : sampleAnswersForQuestion3InPort
            for ans in questions3Answers {
                let answerString = NSAttributedString(string: ans, attributes: answerAttr)
                let answerRect = CGRect(x: dashedLiensXAxis , y: qustn3WrtngAreaYAxis - answersY + 2, width: answerString.size().width, height: answerString.size().height)
                answerString.draw(in: answerRect)
                qustn3WrtngAreaYAxis += dashedLinesVerticalGapValue
            }
            //question4 answers
            var qustn4WrtngAreaYAxis = templateInfo.screenSize.height*CGFloat(qustn4WrtngAreaDashedLinesY)/100
            let questions4Answers = isLandscape ? sampleAnswersForQuestion4InLand : sampleAnswersForQuestion4InPort
            for ans in questions4Answers {
                let answerString = NSAttributedString(string: ans, attributes: answerAttr)
                let answerRect = CGRect(x: dashedLiensXAxis , y: qustn4WrtngAreaYAxis - answersY + 2, width: answerString.size().width, height: answerString.size().height)
                answerString.draw(in: answerRect)
                qustn4WrtngAreaYAxis += dashedLinesVerticalGapValue
            }
            //question5 answers
            var qustn5WrtngAreaYAxis = templateInfo.screenSize.height*CGFloat(qustn5WrtngAreaDashedLinesY)/100
            let  sampleAnswersForQuestion5 = isLandscape ? sampleAnswersForQuestion5IniPadLand :sampleAnswersForQuestion5IniPadPort
            for ans in sampleAnswersForQuestion5 {
                let answerString = NSAttributedString(string: ans, attributes: answerAttr)
                let answerRect = CGRect(x: dashedLiensXAxis , y: qustn5WrtngAreaYAxis - answersY + 2, width: answerString.size().width, height: answerString.size().height)
                answerString.draw(in: answerRect)
                qustn5WrtngAreaYAxis += dashedLinesVerticalGapValue
            }
        }
        let isLandscape = templateInfo.customVariants.isLandscape
        quoteX = isLandscape ? 50.08 : 4.79
        quoteY   = isLandscape ? 8.96 : 13.83
        quoteWidth   = isLandscape ? 45.41 : 90.4
        headingWidth   = isLandscape ? 92.8 : 90.4
        headingX   = isLandscape ? 4.85 : 6.11
        heading1Y   = isLandscape ? 18.02 : 21.85
        heading2Y   = isLandscape ? 31.94 : 35.87
        heading3Y   = isLandscape ? 45.71 : 49.9
        heading4Y   = isLandscape ? 63.9 : 68.7
        heading5Y   = isLandscape ? 81.92 : 82.72
        yearX = isLandscape ? 4.04 : 5.39
        yearY = isLandscape ? 8.96 : 7.82
        
        let titleX = templateInfo.screenSize.width*yearX/100
        let titleY = templateInfo.screenSize.height*yearY/100
        
        let dayInfoFont = UIFont.LoraRegular(20)
        let minimumFontSize : CGFloat = 20
        let dayInfoNewFontSize = UIFont.getScaledFontSizeFor(font: dayInfoFont, screenSize: templateInfo.screenSize, minPointSize: minimumFontSize)
        let dayInfoAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.LoraRegular(dayInfoNewFontSize),
                                                         NSAttributedString.Key.kern : 0.0,
                                                         .foregroundColor : UIColor.init(hexString: "#78787B")];
        let dayInfoText = "Date : January XX, 20XX"
        let dayInfoString = NSMutableAttributedString.init(string: dayInfoText, attributes: dayInfoAttrs)
        let dayInfoRect = CGRect(x: titleX, y: titleY, width: dayInfoString.size().width, height: dayInfoString.size().height)
        dayInfoString.draw(in: dayInfoRect)
        
        self.renderQuoteAndQuestions()
    }
    private func renderiPhoneTemplate(context : CGContext){
        if let templateInfo = self.templateInfo as? FTFiveMinJournalTemplateInfo {
            let dayTemplateOBJ = FTFiveMinJournalDayTemplate(templateInfo: templateInfo)
            
            let isLandscape = self.templateInfo.customVariants.isLandscape
            // Rendering sample logo
            
            let logoXPercntage : CGFloat = isLandscape ? 71.59 : 50.38
            let logoYPercntage : CGFloat = isLandscape ? 41.96 : 1.48
            let logoWidthPercntage : CGFloat = isLandscape ? 26.08 : 46.40
            
            let logoXValue = templateInfo.screenSize.width*logoXPercntage/100
            let logoYValue = templateInfo.screenSize.height*logoYPercntage/100
            let logoWidthValue = templateInfo.screenSize.width*logoWidthPercntage/100
            
            let sampleEntryImage = UIImage(named: "samplePageSampleLogo")
            let sampleEntryRect = CGRect(x: logoXValue, y: logoYValue, width: logoWidthValue, height: logoWidthValue)
            
            if isLandscape {
                dayTemplateOBJ.renderiPhoneTemplate(context: context)
                sampleEntryImage?.draw(in: sampleEntryRect)
            }
            else{
                sampleEntryImage?.draw(in: sampleEntryRect)
                dayTemplateOBJ.renderiPhoneTemplate(context: context)
            }
            let qustn1WrtngAreaDashedLinesY : CGFloat = isLandscape ? 29.76 : 26.24
            let qustn2WrtngAreaDashedLinesY : CGFloat =  isLandscape ? 52.87 : 41.57
            let qustn3WrtngAreaDashedLinesY : CGFloat =  isLandscape ?  76.70 : 56.90
            let qustn4WrtngAreaDashedLiensY : CGFloat =  isLandscape ? 29.76 :  74.72
            let qustn5WrtngAreaDashedLinesY : CGFloat = isLandscape ? 52.87 : 90.05
            let dashedLinesVerticalGapY : CGFloat = isLandscape ? 9.06 : 4.14
            
            var dashedLinesVerticalGapValue = templateInfo.screenSize.height*CGFloat(dashedLinesVerticalGapY)/100
            
            var answersMinimumFontSize : CGFloat = isLandscape ? 12 :16
            var answersFont = isLandscape ? UIFont.dancingScriptRegular(14) : UIFont.dancingScriptRegular(16)
            if self.templateInfo.customVariants.selectedDevice.identifier == "mobile1" {
                answersFont = isLandscape ? UIFont.dancingScriptRegular(12): UIFont.dancingScriptRegular(14)
                answersMinimumFontSize = 10
            }
            let answersNewFontSize = UIFont.getScaledFontSizeFor(font: answersFont, screenSize: self.templateInfo.screenSize, minPointSize: answersMinimumFontSize)
            
            let answerAttr  = [
                NSAttributedString.Key.font: UIFont.dancingScriptRegular(answersNewFontSize),
                NSAttributedString.Key.foregroundColor: UIColor.init(hexString: "#06438B"),
                NSAttributedString.Key.kern : 0.0] as [NSAttributedString.Key : Any]
            
            var answersX = isLandscape ? templateInfo.screenSize.width*CGFloat(2.99)/100 : templateInfo.screenSize.width*CGFloat(6.4)/100
            let answersY = isLandscape ? templateInfo.screenSize.height*CGFloat(5.31)/100 :templateInfo.screenSize.height*CGFloat(2.62)/100
            // question1 answers
            var qustn1WrtngAreaYAxis = templateInfo.screenSize.height*CGFloat(qustn1WrtngAreaDashedLinesY)/100
            let questions1Answers = isLandscape ? sampleAnswersForQuestion1iPhoneLand : sampleAnswersForQuestion1iPhonePort
            for ans in questions1Answers {
                let answerString = NSAttributedString(string: ans, attributes: answerAttr)
                let answerRect = CGRect(x: answersX, y: qustn1WrtngAreaYAxis - answersY , width: answerString.size().width, height: answerString.size().height)
                answerString.draw(in: answerRect)
                qustn1WrtngAreaYAxis += dashedLinesVerticalGapValue
            }
            
            //question2 answers
            var qustn2WrtngAreaYAxis = templateInfo.screenSize.height*CGFloat(qustn2WrtngAreaDashedLinesY)/100
            let question2Answers = isLandscape ? sampleAnswersForQuestion2iPhoneLand : sampleAnswersForQuestion2iPhone
            for ans in question2Answers {
                let answerString = NSAttributedString(string: ans, attributes: answerAttr)
                let answerRect = CGRect(x: answersX, y: qustn2WrtngAreaYAxis - answersY, width: answerString.size().width, height: answerString.size().height)
                answerString.draw(in: answerRect)
                qustn2WrtngAreaYAxis += dashedLinesVerticalGapValue
            }
            //question3 answers
            var qustn3WrtngAreaYAxis = templateInfo.screenSize.height*CGFloat(qustn3WrtngAreaDashedLinesY)/100
            let questions3Answers = isLandscape ? sampleAnswersForQuestion3InLandiPhone : sampleAnswersForQuestion3InPortiPhone
            for ans in questions3Answers {
                let answerString = NSAttributedString(string: ans, attributes: answerAttr)
                let answerRect = CGRect(x: answersX, y: qustn3WrtngAreaYAxis - answersY, width: answerString.size().width, height: answerString.size().height)
                answerString.draw(in: answerRect)
                qustn3WrtngAreaYAxis += dashedLinesVerticalGapValue
            }
            //question4 answers
            var qustn4WrtngAreaYAxis = templateInfo.screenSize.height*CGFloat(qustn4WrtngAreaDashedLiensY)/100
            if isLandscape {
                answersX = templateInfo.screenSize.width*CGFloat(51.57)/100
            }
            let questions4Answers = isLandscape ? sampleAnswersForQuestion4InLandiPhone : sampleAnswersForQuestion4InPortiPhone
            for ans in questions4Answers {
                let answerString = NSAttributedString(string: ans, attributes: answerAttr)
                let answerRect = CGRect(x: answersX, y: qustn4WrtngAreaYAxis - answersY, width: answerString.size().width, height: answerString.size().height)
                answerString.draw(in: answerRect)
                qustn4WrtngAreaYAxis += dashedLinesVerticalGapValue
            }
            //question5 answers
            let qustn5WrtngAreaYAxis = templateInfo.screenSize.height*CGFloat(qustn5WrtngAreaDashedLinesY)/100
            var answerY = qustn5WrtngAreaYAxis - answersY
            if isLandscape {
                answersX = templateInfo.screenSize.width*CGFloat(51.57)/100
                answerY = qustn5WrtngAreaYAxis + templateInfo.screenSize.height*CGFloat(2.11)/100
                dashedLinesVerticalGapValue = templateInfo.screenSize.height*CGFloat(5.5)/100
            }
            let sampleAnswersForQuestion5 = isLandscape ? sampleAnswersForQuestion5iPhoneLand : sampleAnswersForQuestion5iPhoneport
            for ans in sampleAnswersForQuestion5 {
                let answerString = NSAttributedString(string: ans, attributes: answerAttr)
                let answerRect = CGRect(x: answersX, y: answerY, width: answerString.size().width, height: answerString.size().height)
                answerString.draw(in: answerRect)
                answerY += dashedLinesVerticalGapValue
            }
        }
        let isLandscape = templateInfo.customVariants.isLandscape
        quoteX = isLandscape ? 52.02 : 5.33
        quoteY   = isLandscape ? 6.04 : 8.70
        quoteWidth   = isLandscape ? 44.97 : 89.33
        headingWidth   = isLandscape ? 45.87 : 89.33
        headingX   = isLandscape ? 2.99 : 6.4
        heading1Y   = isLandscape ? 21.14 : 19.61
        heading2Y   = isLandscape ? 44.86 : 34.94
        heading3Y   = isLandscape ? 67.97 : 50.27
        heading4Y   = isLandscape ? 21.14 : 68.09
        heading5Y   = isLandscape ? 43.8 : 83.42
        yearX = isLandscape ? 2.99 : 5.6
        yearY = isLandscape ? 5.45 : 2.90
        
        let titleX = templateInfo.screenSize.width*yearX/100
        let titleY = templateInfo.screenSize.height*yearY/100
        
        let dayInfoFont = UIFont.LoraRegular(14)
        let minimumFontSize : CGFloat = 11
        let dayInfoNewFontSize = UIFont.getScaledFontSizeFor(font: dayInfoFont, screenSize: templateInfo.screenSize, minPointSize: minimumFontSize)
        let dayInfoAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.LoraRegular(dayInfoNewFontSize),
                                                         NSAttributedString.Key.kern : 0.0,
                                                         .foregroundColor : UIColor.init(hexString: "#78787B")];
        let dayInfoText = "20XX / January XX"
        let dayInfoString = NSMutableAttributedString.init(string: dayInfoText, attributes: dayInfoAttrs)
        let dayInfoRect = CGRect(x: titleX, y: titleY, width: dayInfoString.size().width, height: dayInfoString.size().height)
        dayInfoString.draw(in: dayInfoRect)
        
        self.renderQuoteAndQuestions()
    }
    func renderQuoteAndQuestions(){
        //Drawing the quote data
        
        let isIpad = templateInfo.customVariants.selectedDevice.isiPad
        let isLandscape = templateInfo.customVariants.isLandscape
        
        let quoteFont = self.templateInfo.customVariants.selectedDevice.isiPad ? UIFont.LoraItalic(20) : UIFont.LoraItalic(14)
        let quoteminimumFontSize : CGFloat = isIpad ? 15 : 11
        let quoteNewFontSize = UIFont.getScaledFontSizeFor(font: quoteFont, screenSize: templateInfo.screenSize, minPointSize: quoteminimumFontSize)
        var quoteAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.LoraItalic(quoteNewFontSize),
                                                         NSAttributedString.Key.kern : 0.0,
                                                         .foregroundColor : UIColor.init(hexString: "#78787B")];
        
    
        let style=NSMutableParagraphStyle.init()
        style.alignment = isLandscape ? NSTextAlignment.right : NSTextAlignment.center
        style.lineBreakMode = .byWordWrapping
        quoteAttrs[.paragraphStyle] = style
        
        let quoteX = templateInfo.screenSize.width*quoteX/100
        let quoteY = templateInfo.screenSize.height*quoteY/100
        let quoteRectWidth = templateInfo.screenSize.width*quoteWidth/100
        
        let quoteString=NSAttributedString.init(string: quote, attributes: quoteAttrs);
        let expectedSize:CGSize=quoteString.requiredSizeForAttributedStringConStraint(to: CGSize(width: quoteRectWidth, height: 60))
        quoteString.draw(in: CGRect(x: quoteX, y: quoteY, width: quoteRectWidth, height: expectedSize.height))
        
        let authorFont = isIpad ? UIFont.LoraItalic(18) :  UIFont.LoraItalic(13)
        let authorMinimumFontSize : CGFloat = isIpad ? 14 : 10
        let authorNewFontSize = UIFont.getScaledFontSizeFor(font: authorFont, screenSize: templateInfo.screenSize, minPointSize: authorMinimumFontSize)
        let authorAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.LoraItalic(authorNewFontSize),
                                                         NSAttributedString.Key.kern : 0.0,
                                                         .foregroundColor : UIColor.init(hexString: "#78787B"),
                                                         .paragraphStyle : style];
        
        let authorString=NSAttributedString.init(string: "-" + author, attributes: authorAttrs);
        let topGapBWQuoteAndAuthor : CGFloat = isIpad ? (isLandscape ? 7 : 10) :(isLandscape ? 4 : 0)
        let authorY = quoteY + expectedSize.height + topGapBWQuoteAndAuthor
        let authorRect = CGRect(x: quoteX, y: authorY , width: quoteRectWidth, height: 30)
        authorString.draw(in: authorRect)
        
        
        style.alignment=NSTextAlignment.left
        let headingRectWidth = templateInfo.screenSize.width*headingWidth/100
        let headingsFont = isIpad ? UIFont.LoraRegular(20) : UIFont.LoraRegular(12)
        let headingsminimumFontSize : CGFloat = isIpad ? 16 : 10
        let headingsNewFontSize = UIFont.getScaledFontSizeFor(font: headingsFont, screenSize: templateInfo.screenSize, minPointSize: headingsminimumFontSize)
        
        let headingsAttrs: [NSAttributedString.Key : Any] = [.font : UIFont.LoraRegular(headingsNewFontSize),
                                                         NSAttributedString.Key.kern : 0.0,
                                                         .foregroundColor : UIColor.init(hexString: "#78787B"),
                                                         .paragraphStyle : style];
        var headingX = templateInfo.screenSize.width*headingX/100
        let heading1Y = templateInfo.screenSize.height*heading1Y/100
        
        let heading1String = NSAttributedString.init(string: dayPageHeadings[0], attributes: headingsAttrs);
        let heading1Rect = CGRect(x: headingX, y: heading1Y , width: headingRectWidth, height: 30)
        heading1String.draw(in: heading1Rect)
        
        
        let heading2Y = templateInfo.screenSize.height*heading2Y/100
        
        let heading2String = NSAttributedString.init(string: dayPageHeadings[1], attributes: headingsAttrs);
        let heading2Rect = CGRect(x: headingX, y: heading2Y , width: headingRectWidth, height: 30)
        heading2String.draw(in: heading2Rect)
        
        let heading3Y = templateInfo.screenSize.height*heading3Y/100
        
        let heading3String = NSAttributedString.init(string: dayPageHeadings[2], attributes: headingsAttrs);
        let heading3Rect = CGRect(x: headingX, y: heading3Y , width: headingRectWidth, height: 30)
        heading3String.draw(in: heading3Rect)
        
        if !isIpad, isLandscape {
            headingX = templateInfo.screenSize.width*52.19/100
        }
        let heading4Y = templateInfo.screenSize.height*heading4Y/100
        let heading4String = NSAttributedString.init(string: dayPageHeadings[3], attributes: headingsAttrs);
        let heading4Rect = CGRect(x: headingX, y: heading4Y , width: headingRectWidth, height: 30)
        heading4String.draw(in: heading4Rect)
        
        let heading5Y = templateInfo.screenSize.height*heading5Y/100
        
        let heading5String = NSAttributedString.init(string: dayPageHeadings[4], attributes: headingsAttrs);
        let heading5Rect = CGRect(x: headingX, y: heading5Y , width: headingRectWidth, height: 30)
        heading5String.draw(in: heading5Rect)
        //dayRectsInfo.append(currentDayRectsInfo)
    }
}
