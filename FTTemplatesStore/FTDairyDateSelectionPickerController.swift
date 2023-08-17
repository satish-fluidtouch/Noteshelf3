//
//  FTDairyDateSelectionPickerController.swift
//  FTTemplatesStore
//
//  Created by Amar Udupa on 14/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTDairyDateSelectionPickerController:  UIViewController {
    var templateInfo: TemplateInfo?
    weak var delegate: FTDairyDateSelectionPickerDelegate?
    var pickerYearData: [String] = []
    var pickerMonthData: [String] = []

    static func presentDatePicker(template: TemplateInfo?
                                  , delegate indelegate: FTDairyDateSelectionPickerDelegate
                                  ,onViewController: UIViewController) {
#if targetEnvironment(macCatalyst)
        if let vc = UIStoryboard.init(name: "FTTemplatesStore", bundle: storeBundle).instantiateViewController(withIdentifier: "FTDairyDatePickerController_Mac") as? FTDairyDatePickerController_Mac {
            vc.modalPresentationStyle = .formSheet
            vc.delegate = indelegate
            vc.templateInfo = template
            onViewController.present(vc, animated: true)
        }
#else
        if let vc = UIStoryboard.init(name: "FTTemplatesStore", bundle: storeBundle).instantiateViewController(withIdentifier: "FTDairyDateSelectionPicker_iOS") as? FTDairyDateSelectionPicker_iOS {
            vc.modalPresentationStyle = .formSheet
            vc.delegate = indelegate
            vc.templateInfo = template
            onViewController.present(vc, animated: true)
        }
#endif
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let date = Date()
        let year = date.year() - 1

        for i in 0...year + 1000 {
            pickerYearData.append("\(i + 1)")
        }

        let dateFormatter = DateFormatter()
        let currentLocale = Locale.current.language.languageCode?.identifier.lowercased() ?? "en"
        #if DEBUG
        debugPrint("Locale: " + currentLocale)
        #endif
        dateFormatter.locale = Locale.init(identifier: NSCalendar.calLocale(currentLocale))
        pickerMonthData = dateFormatter.monthSymbols!
        
        self.preferredContentSize = CGSize.init(width: 330, height: 450)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
    }
    
    func onDone( startMonth selectedFromMonth: Int
                 , startYear selectedFromYear: Int
                 , endMonth selectedToMonth: Int
                 ,endYear selectedToYear: Int) {
        
        var templateType = 0;
        if let temp = templateInfo?.fileName, let fileType = FTDiaryFileType(rawValue: temp) {
            templateType = fileType.type;
        }

        let calender = NSCalendar.gregorian()
        let fromDate = calender.date(month: selectedFromMonth, year: selectedFromYear)!
        let toDate = calender.date(month: selectedToMonth, year: selectedToYear)!

        var isTheSelctionFine = false
        var alertMessage = ""
        if fromDate.compare(toDate) == ComparisonResult.orderedAscending || fromDate.compare(toDate) == ComparisonResult.orderedSame {
            if templateType != 8 && fromDate.numberOfMonths(toDate) <= 12{
                isTheSelctionFine = true
            }
            else if templateType != 8 && fromDate.numberOfMonths(toDate) > 12{
                alertMessage = FTDiaryGeneratorLocalizedString("PeriodExceedsTweleveMonths", comment: "Period cannot be greater than 12 months")
            }
            else if templateType == 8 && fromDate.numberOfMonths(toDate) == 12 { // For planner diary
                isTheSelctionFine = true
            }
            else if templateType == 8 && (fromDate.numberOfMonths(toDate) < 12 || fromDate.numberOfMonths(toDate) > 12){ // For planner diary, period should be exactly 12 months as the diary is designed for 12 months.
                alertMessage = FTDiaryGeneratorLocalizedString("PeriodIsNotTweleveMonths", comment: "Period cannot be greater than 12 months")
            }

        } else {
            alertMessage = FTDiaryGeneratorLocalizedString("EndDateIsEarlier", comment: "The End Date is earlier than the Start Date")
        }

        if isTheSelctionFine {
            let fromDate = calender.date(month: selectedFromMonth, year: selectedFromYear)!
            let numberOfDays = toDate.numberOfDaysInMonth();
            let toDate = calender.date(month: selectedToMonth, year: selectedToYear,day: numberOfDays)!;
            let _delegate = delegate
            self.dismiss(animated: true) {
                _delegate?.onDatesSelected(self, startDate: fromDate, endDate: toDate)
            }

        } else {
            let alert = UIAlertController.init(title: alertMessage, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK",comment: "OK"), style: .cancel, handler: nil))
            self.present(alert,animated: true, completion: nil)
        }
    }
}

