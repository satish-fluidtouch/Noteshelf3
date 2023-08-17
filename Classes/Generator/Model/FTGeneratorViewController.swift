//
//  FTGeneratorViewController.swift
//  Noteshelf
//
//  Created by sreenu cheedella on 02/01/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

protocol FTGeneratorViewControllerDelegate: AnyObject {
    func onDatesSelected(_ generatorController: FTGeneratorViewController, startDate: Date, endDate: Date)
}

class FTGeneratorViewController: UIViewController {
    weak var delegate: FTGeneratorViewControllerDelegate?
    
    @IBOutlet var fromStackView: UIStackView!
    @IBOutlet var toStackView: UIStackView!
    
    @IBOutlet var fromDate: UILabel!
    @IBOutlet var fromDatePickerView: UIPickerView!
    
    @IBOutlet var toDate: UILabel!
    @IBOutlet var toDatePickerView: UIPickerView!
    
    @IBOutlet var doneButton: UIButton!
    
    fileprivate var fromPickerDataSource: FTFromDatePickerDataSource!
    fileprivate var toPickerDataSource: FTToDatePickerDataSource!
    
    var pickerYearData: [String] = []
    var templateType : Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.fromStackView.layer.cornerRadius = 8.0
        self.toStackView.layer.cornerRadius = 8.0
        self.fromStackView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.toStackView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]

        doneButton.isEnabled = true
        fromDate.text = FTDiaryGeneratorLocalizedString("StartDate", comment: "Start Date")
        toDate.text = FTDiaryGeneratorLocalizedString("EndDate", comment: "End Date")
        doneButton.setTitle(NSLocalizedString("Done", comment: "Done"), for: .normal)
        
        let date = Date()
        let month = date.month() - 1
        let year = date.year() - 1
        
        for i in 0...year + 1000 {
            pickerYearData.append("\(i + 1)")
        }
        
        let dateFormatter = DateFormatter()
        let currentLocale = Locale.current.languageCode?.lowercased() ?? "en"
        #if DEBUG
        debugPrint("Locale: " + currentLocale)
        #endif
        dateFormatter.locale = Locale.init(identifier: NSCalendar.calLocale(currentLocale))
        let pickerData: [String] = dateFormatter.monthSymbols!
        
        self.fromPickerDataSource = FTFromDatePickerDataSource.init(pickerData: pickerData, pickerYearData: pickerYearData)
        self.fromDatePickerView.delegate = self.fromPickerDataSource
        self.fromDatePickerView.dataSource = self.fromPickerDataSource
        
        self.toPickerDataSource = FTToDatePickerDataSource.init(pickerData: pickerData, pickerYearData: pickerYearData)
        self.toDatePickerView.delegate = self.toPickerDataSource
        self.toDatePickerView.dataSource = self.toPickerDataSource

        fromDatePickerView.selectRow(month, inComponent: 0, animated: true)
        fromDatePickerView.selectRow(year, inComponent: 1, animated: true)
        toDatePickerView.selectRow(month - 1 == -1 ? 11 : month - 1 , inComponent: 0, animated: true)
        toDatePickerView.selectRow(month - 1 == -1 ? year : year + 1, inComponent: 1, animated: true)
        
        self.preferredContentSize = CGSize.init(width: 330, height: 450)
    }
    
    @IBAction func onDoneClicked(_ sender: Any) {
        let selectedFromYear = Int(self.pickerYearData[fromDatePickerView.selectedRow(inComponent: 1)])!
        let selectedToYear = Int(self.pickerYearData[toDatePickerView.selectedRow(inComponent: 1)])!
        let selectedFromMonth = fromDatePickerView.selectedRow(inComponent: 0) + 1
        let selectedToMonth = toDatePickerView.selectedRow(inComponent: 0) + 1

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
            
            // saving month and year seperately in user defaults instead of dates
            FTUserDefaults.saveDiaryRecentStartMonth(selectedFromMonth)
            FTUserDefaults.saveDiaryRecentEndMonth(selectedToMonth)
            FTUserDefaults.saveDiaryRecentStartYear(selectedFromYear)
            FTUserDefaults.saveDiaryRecentEndYear(selectedToYear)

            delegate?.onDatesSelected(self, startDate: fromDate, endDate: toDate)
        } else {
            let alert = UIAlertController.init(title: alertMessage, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK",comment: "OK"), style: .cancel, handler: nil))
            self.present(alert,animated: true, completion: nil)
        }
    }
}

private class FTFromDatePickerDataSource: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
    var pickerData: [String]!
    var pickerYearData: [String]!

    init(pickerData: [String], pickerYearData: [String]) {
        self.pickerData = pickerData
        self.pickerYearData = pickerYearData
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return component == 0 ? pickerData.count : self.pickerYearData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        let title = component == 0 ? pickerData[row] : self.pickerYearData[row]
        let pickerLabel = UILabel()
        pickerLabel.textColor = .headerColor
        pickerLabel.text = title
        pickerLabel.font = UIFont.appFont(for: .regular, with: 17)
        pickerLabel.textAlignment = NSTextAlignment.center
        return pickerLabel
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return CGFloat(130)
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return CGFloat(30)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //This will be called when user scrolls the pickerView
    }
}

private class FTToDatePickerDataSource: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
    var pickerData: [String]!
    var pickerYearData: [String]!
    
    required init(pickerData: [String], pickerYearData: [String]) {
        self.pickerData = pickerData
        self.pickerYearData = pickerYearData
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return component == 0 ? pickerData.count : self.pickerYearData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        let title = component == 0 ? pickerData[row] : self.pickerYearData[row]
        let pickerLabel = UILabel()
        pickerLabel.textColor = .headerColor
        pickerLabel.text = title
        pickerLabel.font = UIFont.appFont(for: .regular, with: 17)
        pickerLabel.textAlignment = NSTextAlignment.center
        return pickerLabel
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return CGFloat(130)
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return CGFloat(30)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //This will be called when user scrolls the pickerView
    }
}
