//
//  FTDairyDateSelectionPicker.swift
//  FTTemplatesStore
//
//  Created by Siva on 01/06/23.
//

import UIKit
import FTStyles

protocol FTDairyDateSelectionPickerDelegate: AnyObject {
    func onDatesSelected(_ generatorController: FTDairyDateSelectionPickerController, startDate: Date, endDate: Date)
}

enum FTDiaryFileType: String {
    case Digital_Diaries_Colorful_Planner
    case Digital_Diaries_Midnight
    case Digital_Diaries_Classic
    case Digital_Diaries_Colorful_Planner_Dark
    case Digital_Diaries_Modern
    case Digital_Diaries_Day_and_Night_Journal
    var type: Int {
        switch self {
        case .Digital_Diaries_Colorful_Planner:
            return 8
        case .Digital_Diaries_Midnight:
            return 6
        case .Digital_Diaries_Classic:
            return 4
        case .Digital_Diaries_Colorful_Planner_Dark:
            return 8
        case .Digital_Diaries_Modern:
            return 4
        case .Digital_Diaries_Day_and_Night_Journal:
            return 7
        }
    }

}

class FTDairyDateSelectionPicker_iOS: FTDairyDateSelectionPickerController {
    @IBOutlet var fromStackView: UIStackView!
    @IBOutlet var toStackView: UIStackView!

    @IBOutlet var fromDate: UILabel!
    @IBOutlet var fromDatePickerView: UIPickerView!

    @IBOutlet var toDate: UILabel!
    @IBOutlet var toDatePickerView: UIPickerView!

    @IBOutlet var doneButton: UIButton!

    fileprivate var fromPickerDataSource: FTFromDatePickerDataSource!
    fileprivate var toPickerDataSource: FTToDatePickerDataSource!

    var templateType : Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        if let info = templateInfo {
           let fileName = info.fileName
            templateType = FTDiaryFileType(rawValue: fileName)?.type ?? 0
        }

        self.fromStackView.layer.cornerRadius = 8.0
        self.toStackView.layer.cornerRadius = 8.0
        self.fromStackView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.toStackView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]

        doneButton.isEnabled = true
        // TODO: Siva
        fromDate.text = FTDiaryGeneratorLocalizedString("StartDate", comment: "Start Date")
        toDate.text = FTDiaryGeneratorLocalizedString("EndDate", comment: "End Date")
        doneButton.setTitle(NSLocalizedString("Done", comment: "Done"), for: .normal)

        let date = Date()
        let month = date.month() - 1
        let year = date.year() - 1

        self.fromPickerDataSource = FTFromDatePickerDataSource.init(pickerData: self.pickerMonthData, pickerYearData: self.pickerYearData)
        self.fromDatePickerView.delegate = self.fromPickerDataSource
        self.fromDatePickerView.dataSource = self.fromPickerDataSource

        self.toPickerDataSource = FTToDatePickerDataSource.init(pickerData: self.pickerMonthData, pickerYearData: self.pickerYearData)
        self.toDatePickerView.delegate = self.toPickerDataSource
        self.toDatePickerView.dataSource = self.toPickerDataSource

        fromDatePickerView.selectRow(month, inComponent: 0, animated: true)
        fromDatePickerView.selectRow(year, inComponent: 1, animated: true)
        toDatePickerView.selectRow(month - 1 == -1 ? 11 : month - 1 , inComponent: 0, animated: true)
        toDatePickerView.selectRow(month - 1 == -1 ? year : year + 1, inComponent: 1, animated: true)
    }

    @IBAction func onDoneClicked(_ sender: Any) {
        let selectedFromYear = Int(self.pickerYearData[fromDatePickerView.selectedRow(inComponent: 1)])!
        let selectedToYear = Int(self.pickerYearData[toDatePickerView.selectedRow(inComponent: 1)])!
        let selectedFromMonth = fromDatePickerView.selectedRow(inComponent: 0) + 1
        let selectedToMonth = toDatePickerView.selectedRow(inComponent: 0) + 1

        self.onDone(startMonth: selectedFromMonth, startYear: selectedFromYear, endMonth: selectedToMonth, endYear: selectedToYear);
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

func FTDiaryGeneratorLocalizedString(_ key: String, comment: String?) -> String {
    return NSLocalizedString(key,
                             tableName: "Localizable",
                             bundle: Bundle.main,
                             value: "", comment: comment ?? "")
}
