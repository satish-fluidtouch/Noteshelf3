//
//  FTdairyDatePickerViewController_Mac.swift
//  FTTemplatesStore
//
//  Created by Amar Udupa on 14/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTdairyDatePickerViewControllerDelegate_Mac: NSObjectProtocol {
    func titleFor(row: Int,component: Int) -> String;
    func numberOfRows(for component: Int) -> Int;
}

class FTDairyDatePickerController_Mac: FTDairyDateSelectionPickerController {
    @IBOutlet weak var fromTitleLabel: UILabel?
    @IBOutlet weak var toTitleLabel: UILabel?

    @IBOutlet weak var doneButton: UIButton?;
    @IBOutlet weak var cancelButton: UIButton?;

    private weak var fromDatePicker: FTdairyDatePickerViewController_Mac?;
    private weak var toDatePicker: FTdairyDatePickerViewController_Mac?;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.doneButton?.configuration?.title = "Done".localized;
        self.cancelButton?.configuration?.title = "Cancel".localized;

        self.fromTitleLabel?.text = FTDiaryGeneratorLocalizedString("StartDate", comment: "Start Date")
        self.toTitleLabel?.text = FTDiaryGeneratorLocalizedString("EndDate", comment: "End Date")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
    }
            
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            let date = Date()
            let month = date.month() - 1
            let year = date.year() - 1

            self.fromDatePicker?.selectRow(month, inComponent: 0, animated: true)
            self.fromDatePicker?.selectRow(year, inComponent: 1, animated: true)
            self.toDatePicker?.selectRow(month - 1 == -1 ? 11 : month - 1 , inComponent: 0, animated: true)
            self.toDatePicker?.selectRow(month - 1 == -1 ? year : year + 1, inComponent: 1, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "From_Date_Picker" {
            fromDatePicker = segue.destination as? FTdairyDatePickerViewController_Mac;
            fromDatePicker?.delegate = self;
        }
        else if segue.identifier == "To_Date_Picker" {
            toDatePicker = segue.destination as? FTdairyDatePickerViewController_Mac;
            toDatePicker?.delegate = self;
        }
    }
    
    @IBAction func cancelButtontapped(_ sender:Any) {
        self.dismiss(animated: true);
    }
    
    @IBAction func doneButtontapped(_ sender:Any) {
        
        let startYear = self.fromDatePicker?.selectedRow(inComponent: 1) ?? 0;
        let startMonth = self.fromDatePicker?.selectedRow(inComponent: 0) ?? 0;
        let endYear = self.toDatePicker?.selectedRow(inComponent: 1) ?? 0;
        let endMonth = self.toDatePicker?.selectedRow(inComponent: 0) ?? 0;
        
        
        let selectedFromYear = Int(self.pickerYearData[startYear])!
        let selectedToYear = Int(self.pickerYearData[endYear])!
        let selectedFromMonth = startMonth + 1
        let selectedToMonth = endMonth + 1

        self.onDone(startMonth: selectedFromMonth, startYear: selectedFromYear, endMonth: selectedToMonth, endYear: selectedToYear);
    }
}


extension FTDairyDatePickerController_Mac: FTdairyDatePickerViewControllerDelegate_Mac {
    func numberOfRows(for component: Int) -> Int {
        return component == 0 ? self.pickerMonthData.count : self.pickerYearData.count;
    }
    
    func titleFor(row: Int, component: Int) -> String {
        return component == 0 ? self.pickerMonthData[row] : self.pickerYearData[row]
    }
}

class FTdairyDatePickerViewController_Mac: UIViewController {
    @IBOutlet weak var monthTableView: UITableView?;
    @IBOutlet weak var yearTableView: UITableView?;
    weak var delegate: FTdairyDatePickerViewControllerDelegate_Mac?;
        
    override func viewDidLoad() {
        super.viewDidLoad()

        monthTableView?.register(UITableViewCell.self, forCellReuseIdentifier: "monthTableViewCell");
        yearTableView?.register(UITableViewCell.self, forCellReuseIdentifier: "yearTableViewCell");
        // Do any additional setup after loading the view.
    }
    
    func selectRow(_ row: Int, inComponent: Int,animated: Bool) {
        let indexPath = IndexPath(row: row, section: 0);
        if inComponent == 0 {
            self.monthTableView?.scrollToRow(at: indexPath, at: .middle, animated: animated)
            self.monthTableView?.selectRow(at: indexPath, animated: animated, scrollPosition: .middle);
        }
        else {
            self.yearTableView?.scrollToRow(at: indexPath, at: .middle, animated: animated)
            self.yearTableView?.selectRow(at:indexPath , animated: animated, scrollPosition: .middle);
        }
    }

}

extension FTdairyDatePickerViewController_Mac: UITableViewDelegate,UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.monthTableView {
            return self.delegate?.numberOfRows(for: 0) ?? 0;
        }
        else if tableView == self.yearTableView {
            return self.delegate?.numberOfRows(for: 1) ?? 0;
        }
        return 0;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellidentifier: String;
        let componenet: Int
        if tableView == monthTableView {
            cellidentifier = "monthTableViewCell";
            componenet = 0;
        }
        else {
            componenet = 1;
            cellidentifier = "yearTableViewCell";
        }
        let  tableViewCell = tableView.dequeueReusableCell(withIdentifier:cellidentifier, for: indexPath);
        if let title = self.delegate?.titleFor(row: indexPath.row, component: componenet) {
            tableViewCell.textLabel?.text = title;
            tableViewCell.textLabel?.font = UIFont.appFont(for: .regular, with: 17);
        }
        tableViewCell.selectionStyle = .blue;
        
        return tableViewCell;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func selectedRow(inComponent component: Int) -> Int {
        if component == 0 {
            return monthTableView?.indexPathForSelectedRow?.row ?? 0
        }
        return yearTableView?.indexPathForSelectedRow?.row ?? 0;
    }
}
