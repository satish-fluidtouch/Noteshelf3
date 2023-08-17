//
//  File.swift
//  
//
//  Created by Narayana on 16/05/22.
//

import Foundation

public let DigitalDiaryStartDateKey = "digitalDiaryStartDate"
public let DigitalDiaryEndDateKey = "digitalDiaryEndDate"
public let DigitalDiaryStartMonthKey = "digitalDiaryStartMonth"
public let DigitalDiaryEndMonthKey = "digitalDiaryEndMonth"
public let DigitalDiaryStartYearKey = "digitalDiaryStartYear"
public let DigitalDiaryEndYearKey = "digitalDiaryEndYear"

// TODO: to revisit FTUserDefaults, Common userdefaults
public class FTCommonUserDefaults: NSObject {
    //MARK: - Shared user defaults
    fileprivate static var staticUserDefaults : UserDefaults? = nil;
    @objc public class func defaults() -> UserDefaults {
        if(nil == staticUserDefaults) {
            staticUserDefaults = UserDefaults.init(suiteName: FTSharedGroupID.getAppGroupID());
        }
        return staticUserDefaults!;
    }

    public class func getVariantsDict(_ key: String, _ defaultsKey: String) -> [String: String] {
        var storedVariants = [String: String]();
        let dictionary = self.defaults().dictionary(forKey: defaultsKey);
        if let dictionary = dictionary,let variants =  dictionary[key] as? [String : String]{
            storedVariants = variants
        }
        return storedVariants
    }

   public class func updateVariantsDict(dict: [String: String], _ key: String, _ defaultsKey: String) {
        var dictionary = self.defaults().dictionary(forKey: defaultsKey);
        if(nil == dictionary) {
            dictionary = [String:AnyObject]();
        }
        if var dictionary = dictionary {
            dictionary[key] = dict
            self.defaults().set(dictionary, forKey: defaultsKey)
            self.defaults().synchronize()
        }
    }
}

extension FTCommonUserDefaults {

   public class func getDiaryRecentStartMonth() -> Int {
        return UserDefaults.standard.integer(forKey: DigitalDiaryStartMonthKey)
    }
    public class func getDiaryRecentEndMonth() -> Int {
        return UserDefaults.standard.integer(forKey: DigitalDiaryEndMonthKey)
    }
    public class func getDiaryRecentStartYear() -> Int {
        return UserDefaults.standard.integer(forKey: DigitalDiaryStartYearKey)
    }
    public class func getDiaryRecentEndYear() -> Int {
        return UserDefaults.standard.integer(forKey: DigitalDiaryEndYearKey)
    }
    public class func saveDiaryRecentStartMonth(_ month : Int) {
        UserDefaults.standard.set(month, forKey: DigitalDiaryStartMonthKey)
    }
    public class func saveDiaryRecentEndMonth(_ month : Int) {
        UserDefaults.standard.set(month, forKey: DigitalDiaryEndMonthKey)
    }
    public class func saveDiaryRecentStartYear(_ year : Int) {
        UserDefaults.standard.set(year, forKey: DigitalDiaryStartYearKey)
    }
    public class func saveDiaryRecentEndYear(_ year : Int) {
        UserDefaults.standard.set(year, forKey: DigitalDiaryEndYearKey)
    }
    public class func getDiaryRecentStartDate() -> Date? {
        return UserDefaults.standard.object(forKey: DigitalDiaryStartDateKey) as? Date
    }
    public class func saveDiaryRecentStartDate(date: Date) {
        UserDefaults.standard.set(date, forKey: DigitalDiaryStartDateKey)
        UserDefaults.standard.synchronize()
    }
    public class func getDiaryRecentEndDate() -> Date? {
        return UserDefaults.standard.object(forKey: DigitalDiaryEndDateKey) as? Date
    }
    public class func saveDiaryRecentEndDate(date: Date) {
        UserDefaults.standard.set(date, forKey: DigitalDiaryEndDateKey)
        UserDefaults.standard.synchronize()
    }
}
