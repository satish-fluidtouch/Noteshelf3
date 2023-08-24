//
//  FTUserDefaults.swift
//  Noteshelf
//
//  Created by Amar on 2/12/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

let shelfExtension = "shelf";
let groupExtension = "group";
let sortIndexExtension = "nsindex"

let NotebookPathKey = "notebookPath"
let LastSelectedCollectionKey = "LAST_SELECTED_COLLECTION"
let LastOpenedDocumentKey = "LAST_OPENED_DOCUMENT"
let LastOpenedGroupKey = "LAST_OPENED_GROUP"
let RandomCoverEnabledKey = "isRandomCoverEnabled"
let SiriRequestedKey = "isSiriRequested"
let DrawBoxForTextKey = "drawBoxForText"
let SwipeFromLeftKey = "swipeFromLeft"
let SwipeFromRightKey = "swipeFromRight"
let DisableHyperlinkKey = "disableHyperlink"
let LockNotebookKey = "lockNotebookInBackground"
let ApplePencilDoubleTapActionKey = "applePencilDoubleTapInteraction"
let clipartFilterVersionKey = "clipartFilterVersion"
let DefaultFontStyleForAll = "defaultFontStyleForAll"
let EraserAutoSelectPreviousToolKey = "shouldAutoSelectPreviousTool"
let EraserEraseEntireStrokeKey = "eraseEntireStroke"
let EraserEraseOptionsShowKey = "eraseOptionsShow"
let EraserEraseHighlighterKey = "eraseHighlighter"
let EraserPencilKey = "erasePencil"
let whiteBoardEnableKey = "whiteBoardEnableKey"
let createWithAudioKey = "createWithAudio"
let quickCreateKey = "quickCreate"

let SortOrderKey = "SORT_ORDER"
let AllNotesModeKey = "isAllNotesMode"
let CurrentPageIndexKey = "currentPageIndex"

let DigitalDiaryStartDateKey = "digitalDiaryStartDate"
let DigitalDiaryEndDateKey = "digitalDiaryEndDate"
let DigitalDiaryStartMonthKey = "digitalDiaryStartMonth"
let DigitalDiaryEndMonthKey = "digitalDiaryEndMonth"
let DigitalDiaryStartYearKey = "digitalDiaryStartYear"
let DigitalDiaryEndYearKey = "digitalDiaryEndYear"


let APP_Installed_Key = "App_installed_on";
let PressureSensitivity_Key = "APPLE_PENCIL_SETTINGS_PRESSURE"

let LastSelectedNonCollectionTypeKey = "LastSelectedNonCollectionType"
let LastSelectedTagKey = "LastSelectedTag"
let NonCollectionModeKey = "NonCollectionMode"
let isFirstLaunchKey = "isFirstLaunch"

class FTUserDefaults : NSObject
{
    class func configure() {
        if let path = Bundle.main.path(forResource: "FTDefaults.plist", ofType: nil), let defaults = NSDictionary(contentsOfFile: path) as? [String:Any] {
            UserDefaults.standard.register(defaults: defaults)
            UserDefaults.standard.synchronize()

        }
        FTUserDefaults.registerDefault(value: NSNumber(value: true), forKey: "isRandomCoverEnabled")
    }

    //MARK: - Shared user defaults
    fileprivate static var staticUserDefaults : UserDefaults? = nil;
    @objc class func defaults() -> UserDefaults {
        if(nil == staticUserDefaults) {
            staticUserDefaults = UserDefaults.init(suiteName: FTSharedGroupID.getAppGroupID());
        }
        return staticUserDefaults!;
    }
    
    @objc static func registerDefault(value : Any,  forKey key: String)
    {
        self.defaults().register(defaults: [key : value]);
        self.defaults().synchronize()
    }
    
    static func saveSelectedNotebook(notebookPath : String) {
        self.defaults().set(URL(fileURLWithPath: notebookPath), forKey: NotebookPathKey)
        self.defaults().synchronize()
    }
    
    static func hasSiriRequested() -> Bool {
        return self.defaults().bool(forKey: SiriRequestedKey)
    }
    
    @objc static func siriRequested(_ value : Bool) {
        self.defaults().set(value, forKey: SiriRequestedKey)
        self.defaults().synchronize()
    }
    
    @objc static func notebookPath() -> URL? {
        return self.defaults().url(forKey: NotebookPathKey)
    }
    
    @objc static func removeSavedNotebook() {
        self.defaults().removeObject(forKey: NotebookPathKey)
        self.defaults().synchronize()
    }
    
    static func lastSelectedCollection() -> String?
    {
        var lastSelectedCollection: String?
        
        if lastSelectedCollection == nil {
            lastSelectedCollection =  self.defaults().string(forKey: LastSelectedCollectionKey);
        }

        return lastSelectedCollection
    }
    
    static func setLastSelectedCollection(_ collectionURL : URL?)
    {
        self.defaults().set(collectionURL?.relativePathWRTCollection(), forKey: LastSelectedCollectionKey)
        self.defaults().synchronize()
    }
    
    static func setRandomKeyEnabled(_ value : Bool) {
        self.defaults().set(value, forKey: RandomCoverEnabledKey)
        self.defaults().synchronize()
    }
    
    static func isRandomKeyEnabled() -> Bool {
        return self.defaults().bool(forKey: RandomCoverEnabledKey)
    }
    
    static func saveDefaultFontForAll(_ data: Dictionary<String, String>) {
        self.defaults().set(data, forKey: DefaultFontStyleForAll)
        self.defaults().synchronize()
    }
    
    static func defaultFontFontAll() -> Dictionary<String, String>? {
        return self.defaults().value(forKey: DefaultFontStyleForAll) as? Dictionary<String, String>
    }
    
    //MARK:- standard default
    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION && !TODAY_WIDGET && !NOTESHELF_ACTION
    @objc class func registerDefaults(isFreshInstall freshInstall : Bool)
    {
        if freshInstall {
            UserDefaults.registerNotebookSettingDefaultsForFreshInstall()
            UserDefaults.standard.set(Date().timeIntervalSinceReferenceDate, forKey: APP_Installed_Key)
        } else {
            if UserDefaults.standard.value(forKey: APP_Installed_Key) == nil {
                //Offsetting the date to track all notes
                let currentDate = Date().offsetDate(-5)
                UserDefaults.standard.set(currentDate.timeIntervalSinceReferenceDate, forKey: APP_Installed_Key)
            }
        }
        UserDefaults.standard.register(defaults: ["SORT_ORDER": NSNumber.init(value: FTShelfSortOrder.byModifiedDate.rawValue as Int),
                                                  APP_Installed_Key : Date().timeIntervalSinceReferenceDate]);
        //TODO:-BySiva
//        FTAddMenuManager.configureMenuItemsForMigration(isFreshInstall:freshInstall)
    }
    
    #endif

    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION && !TODAY_WIDGET && !NOTESHELF_ACTION
    //MARK: - Sort Order
    class func setSortOrder(_ sortOrder : FTShelfSortOrder)
    {
        UserDefaults.standard.set(sortOrder.rawValue, forKey: SortOrderKey);
        UserDefaults.standard.synchronize();
    }
    
    static var appInstalledDate : TimeInterval {
        return UserDefaults.standard.double(forKey: APP_Installed_Key);
    }
    
    class func sortOrder() -> FTShelfSortOrder
    {
        let order = FTShelfSortOrder(rawValue: UserDefaults.standard.integer(forKey: SortOrderKey));
        return order ?? .byModifiedDate; //To avoid crash when overriding manual sort build with develop branch build
    }
    
    class func setApplePencilDoubleTapAction(_ value : FTApplePencilInteractionType) {
        track("double_tap_setting", params: ["setting":value.title()])
        UserDefaults.standard.set(value.rawValue, forKey: ApplePencilDoubleTapActionKey);
        UserDefaults.standard.synchronize();
    }
    
    class func applePencilDoubleTapAction() -> FTApplePencilInteractionType {
        let userDefaults = UserDefaults.standard;
        userDefaults.register(defaults: [ApplePencilDoubleTapActionKey : FTApplePencilInteractionType.systemDefault.rawValue]);
        let value = userDefaults.integer(forKey: ApplePencilDoubleTapActionKey)
        return FTApplePencilInteractionType.init(rawValue : value) ?? FTApplePencilInteractionType.systemDefault;
    }
    class func setAllNotesMode(_ isAllNotes : Bool)
    {
        UserDefaults.standard.set(isAllNotes, forKey: AllNotesModeKey);
        UserDefaults.standard.synchronize();
    }
    class func isAllNotesMode() -> Bool {
        return UserDefaults.standard.bool(forKey: AllNotesModeKey)
    }
        
    @objc
    static func shouldAutoSelectPreviousTool() -> Bool {
        let userDefaults = UserDefaults.standard;
        userDefaults.register(defaults: [EraserAutoSelectPreviousToolKey : false]);
        return userDefaults.bool(forKey: EraserAutoSelectPreviousToolKey)
    }
    
    class func saveAutoSelectPreviousToolTo(_ value : Bool) {
        UserDefaults.standard.set(value, forKey: EraserAutoSelectPreviousToolKey)
        UserDefaults.standard.synchronize();
    }

    class func shouldEraseEntireStroke() -> Bool {
        let userDefaults = UserDefaults.standard;
        userDefaults.register(defaults: [EraserEraseEntireStrokeKey : false]);
        return userDefaults.bool(forKey: EraserEraseEntireStrokeKey)
    }
    
    class func shouldEraseHighlighterOnly() -> Bool {
        let userDefaults = UserDefaults.standard;
        userDefaults.register(defaults: [EraserEraseHighlighterKey : false]);
        return userDefaults.bool(forKey: EraserEraseHighlighterKey)
    }
    
    class func shouldErasePencilOnly() -> Bool {
        let userDefaults = UserDefaults.standard;
        userDefaults.register(defaults: [EraserPencilKey : false]);
        return userDefaults.bool(forKey: EraserPencilKey)
    }
    
    class func saveErasePencilOnlyTo(_ value : Bool) {
        UserDefaults.standard.set(value, forKey: EraserPencilKey)
        UserDefaults.standard.synchronize();
    }
    
    class func saveEraseHighlighterOnlyTo(_ value : Bool) {
        UserDefaults.standard.set(value, forKey: EraserEraseHighlighterKey)
        UserDefaults.standard.synchronize();
    }
    
    class func saveEraseEntireStrokeTo(_ value : Bool) {
        UserDefaults.standard.set(value, forKey: EraserEraseEntireStrokeKey)
        UserDefaults.standard.synchronize();
    }
    
    class func canShowEraseOptions() -> Bool {
        let userDefaults = UserDefaults.standard;
        userDefaults.register(defaults: [EraserEraseOptionsShowKey : true]);
        return userDefaults.bool(forKey: EraserEraseOptionsShowKey)
    }

    class func saveStateOfEraseOptionsTo(_ value : Bool) {
        UserDefaults.standard.set(value, forKey: EraserEraseOptionsShowKey)
        UserDefaults.standard.synchronize();
    }

    #endif
    
    //MARK:- Private -
    fileprivate class func setDefaultsValue(_ value : AnyObject?,forKey key : String)
    {
        if(value != nil) {
            UserDefaults.standard.set(value!, forKey: key);
        }
        else {
            UserDefaults.standard.removeObject(forKey: key);
        }
        UserDefaults.standard.synchronize();
    }
    
}


extension FTUserDefaults //for export settings
{
    class func setExportFormat(_ format : Int)
    {
        UserDefaults.standard.set(format, forKey: "ExportFormat");
        UserDefaults.standard.synchronize();
    }
    
    class func exportFormat() -> Int
    {
        return UserDefaults.standard.integer(forKey: "ExportFormat");
    }
    
    @objc class func setExportIncludeEvernoteTags(_ include : Bool)
    {
        UserDefaults.standard.set(include, forKey: "ExportIncludeEvernoteTags");
        UserDefaults.standard.synchronize();
    }
    
    @objc class func exportIncludeEvernoteTags() -> Bool
    {
        return UserDefaults.standard.bool(forKey: "ExportIncludeEvernoteTags");
    }
    
    class var showPageTemplate: Bool {
        get {
            let userDefaults = UserDefaults.standard
            userDefaults.register(defaults: ["FTPersistenceKey_ShowPageTemplate": true])
            if let val = userDefaults.value(forKey: "FTPersistenceKey_ShowPageBackground") as? NSNumber {
                userDefaults.set(val.boolValue, forKey: "FTPersistenceKey_ShowPageTemplate")
                userDefaults.removeObject(forKey: "FTPersistenceKey_ShowPageBackground")
            }
            return userDefaults.bool(forKey: "FTPersistenceKey_ShowPageTemplate")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "FTPersistenceKey_ShowPageTemplate")
            UserDefaults.standard.synchronize();
        }
    }

    class var exportPageFooter: Bool {
        get {
            let userDefaults = UserDefaults.standard
            userDefaults.register(defaults: ["FTPersistenceKey_ExportPageFooter" : false])
            return userDefaults.bool(forKey: "FTPersistenceKey_ExportPageFooter")
        } set {
            UserDefaults.standard.set(newValue, forKey: "FTPersistenceKey_ExportPageFooter")
            UserDefaults.standard.synchronize()
        }
    }

    class var exportCoverPage: Bool {
        get {
            let userDefaults = UserDefaults.standard
            userDefaults.register(defaults: ["FTPersistenceKey_ExportCoverPage": true])
            return userDefaults.bool(forKey: "FTPersistenceKey_ExportCoverPage")
        } set {
            UserDefaults.standard.set(newValue, forKey: "FTPersistenceKey_ExportCoverPage")
            UserDefaults.standard.synchronize()
        }
    }
}

extension FTUserDefaults //for watch audio file count
{
    class func incrementWatchAudioFileReceived() {
        var currentFileCount = self.totalAudioFileRecievedFromWatch();
        currentFileCount += 1;
        UserDefaults.standard.set(currentFileCount, forKey: "audioRecievedFromWatch");
        UserDefaults.standard.synchronize();
    }

    class func totalAudioFileRecievedFromWatch() -> Int {
        let currentFileCount = UserDefaults.standard.integer(forKey: "audioRecievedFromWatch");
        return currentFileCount;
    }
    
    class func incrementAudioFileSentToWatch() {
        var currentFileCount = self.totalAudioFileSentToWatch();
        currentFileCount += 1;
        UserDefaults.standard.set(currentFileCount, forKey: "audioSentToWatch");
        UserDefaults.standard.synchronize();
    }
    
    class func totalAudioFileSentToWatch() -> Int {
        let currentFileCount = UserDefaults.standard.integer(forKey: "audioSentToWatch");
        return currentFileCount;
    }

}

extension FTUserDefaults // Notebook Options -> Advanced Settings
{
    
    var shouldPresentAppUIOnPresentation: Bool {
        get {
            return UserDefaults.standard.bool(forKey: whiteBoardEnableKey);
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: whiteBoardEnableKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    class func saveDrawBoxForText(_ value : Bool) {
        UserDefaults.standard.set(value, forKey: DrawBoxForTextKey)
        UserDefaults.standard.synchronize()
    }
    
    class func canDrawBoxForText() -> Bool {
        let userDefaults = UserDefaults.standard;
        userDefaults.register(defaults: [DrawBoxForTextKey : true]);
        return userDefaults.bool(forKey: DrawBoxForTextKey)
    }
    
    class func saveSwipeFromLeft(_ value : Bool) {
        UserDefaults.standard.set(value, forKey: SwipeFromLeftKey)
        UserDefaults.standard.synchronize()
    }
    
    @objc class func canSwipeFromLeftForRecent() -> Bool {
        let userDefaults = UserDefaults.standard;
        userDefaults.register(defaults: [SwipeFromLeftKey : true]);
        return userDefaults.bool(forKey: SwipeFromLeftKey)
    }
    
    class func saveSwipeFromRight(_ value : Bool) {
        UserDefaults.standard.set(value, forKey: SwipeFromRightKey)
        UserDefaults.standard.synchronize()
    }
    
    class func lockNotebookInBackground(_ value : Bool) {
        UserDefaults.standard.set(value, forKey: LockNotebookKey)
        UserDefaults.standard.synchronize()
    }
    
    @objc class func canSwipeFromRightForThumbnail() -> Bool {
        let userDefaults = UserDefaults.standard;
        userDefaults.register(defaults: [SwipeFromRightKey : true]);
        return userDefaults.bool(forKey: SwipeFromRightKey)
    }
    
    class func disableHyperlink(_ value : Bool) {
        UserDefaults.standard.set(value, forKey: DisableHyperlinkKey)
        UserDefaults.standard.synchronize()
    }
    
    class func isHyperlinkDisabled() -> Bool {
        let userDefaults = UserDefaults.standard;
        userDefaults.register(defaults: [DisableHyperlinkKey : false]);
        return userDefaults.bool(forKey: DisableHyperlinkKey)
    }
    
    @objc
    class func isNotebookBackgroundLockEnabled() -> Bool {
        let userDefaults = UserDefaults.standard;
        userDefaults.register(defaults: [LockNotebookKey : false]);
        return userDefaults.bool(forKey: LockNotebookKey)
    }
    
    class var disableAutoLock : Bool {
        get {
            let userDefaults = UserDefaults.standard;
            userDefaults.register(defaults: ["DisableAutoLock" : false]);
            return userDefaults.bool(forKey: "DisableAutoLock")
        }
        set {
            let userDefaults = UserDefaults.standard;
            userDefaults.set(newValue, forKey: "DisableAutoLock")
        }
    }
}

extension FTUserDefaults { //Additional Preferences
    class func updateClipartFilterVersion(_ value:Int) {
        UserDefaults.standard.set(value, forKey: clipartFilterVersionKey)
        UserDefaults.standard.synchronize()
    }
    
    class func currentClipartFilterVersion() -> Int {
        let userDefaults = UserDefaults.standard;
        userDefaults.register(defaults: [clipartFilterVersionKey : 1]);
        return userDefaults.integer(forKey: clipartFilterVersionKey)
    }
}

extension FTUserDefaults {
    class func getDiaryRecentStartMonth() -> Int {
        return UserDefaults.standard.integer(forKey: DigitalDiaryStartMonthKey)
    }
    class func getDiaryRecentEndMonth() -> Int {
        return UserDefaults.standard.integer(forKey: DigitalDiaryEndMonthKey)
    }
    class func getDiaryRecentStartYear() -> Int {
        return UserDefaults.standard.integer(forKey: DigitalDiaryStartYearKey)
    }
    class func getDiaryRecentEndYear() -> Int {
        return UserDefaults.standard.integer(forKey: DigitalDiaryEndYearKey)
    }
    class func saveDiaryRecentStartMonth(_ month : Int) {
        UserDefaults.standard.set(month, forKey: DigitalDiaryStartMonthKey)
    }
    class func saveDiaryRecentEndMonth(_ month : Int) {
        UserDefaults.standard.set(month, forKey: DigitalDiaryEndMonthKey)
    }
    class func saveDiaryRecentStartYear(_ year : Int) {
        UserDefaults.standard.set(year, forKey: DigitalDiaryStartYearKey)
    }
    class func saveDiaryRecentEndYear(_ year : Int) {
        UserDefaults.standard.set(year, forKey: DigitalDiaryEndYearKey)
    }
    
    
    class func getDiaryRecentStartDate() -> Date? {
        return UserDefaults.standard.object(forKey: DigitalDiaryStartDateKey) as? Date
    }
    
    class func saveDiaryRecentStartDate(date: Date) {
        UserDefaults.standard.set(date, forKey: DigitalDiaryStartDateKey)
        UserDefaults.standard.synchronize()
    }
    
    class func getDiaryRecentEndDate() -> Date? {
        return UserDefaults.standard.object(forKey: DigitalDiaryEndDateKey) as? Date
    }
    
    class func saveDiaryRecentEndDate(date: Date) {
        UserDefaults.standard.set(date, forKey: DigitalDiaryEndDateKey)
        UserDefaults.standard.synchronize()
    }
}

extension UserDefaults {
    @objc var shapeTypeRawValue: Int {
        get {
            let selectedShapeType = self.integer(forKey: "ShapeType")
            return selectedShapeType
        } set {
            self.set(newValue, forKey: "ShapeType")
            self.synchronize()
        }
    }

    @objc dynamic var userImportCount: Int {
        get {
            return integer(forKey: "userImportCount")
        }
        set {
            self.set(newValue, forKey: "userImportCount")
            self.synchronize()
        }
    }
    
    @objc dynamic var iCloudOn: Bool {
        get {
            return self.bool(forKey: "iCloudOn")
        }
        set {
            self.set(newValue, forKey: "iCloudOn")
            self.synchronize()
        }
    }

    @objc class func isApplePencilEnabled() -> Bool
    {
        #if targetEnvironment(macCatalyst)
        return false;
        #else
        return UserDefaults.standard.bool(forKey: "APPLE_PENCIL_ENABLED")
        #endif
    }
    
    @objc class func setApplePencilEnable(_ enabled : Bool)
    {
        #if !targetEnvironment(macCatalyst)
        UserDefaults.standard.set(enabled, forKey: "APPLE_PENCIL_ENABLED");
        UserDefaults.standard.synchronize();
        #endif
    }
}
// Below functions to persist user selected variants
extension FTUserDefaults {
        class func updateVariantsDict(dict: [String: String], _ key: String, _ defaultsKey: String) {
            var dictionary = self.defaults().dictionary(forKey: defaultsKey);
           if(nil == dictionary) {
               dictionary = [String:AnyObject]();
           }
           if var dictionary = dictionary {
               dictionary[key] = dict
               self.defaults().set(dictionary, forKey: defaultsKey)
                self.defaults().synchronize()
               //UserDefaults.standard.synchronize()
           }
        }
        
        class func getVariantsDict(_ key: String, _ defaultsKey: String) -> [String: String] {
            var storedVariants = [String: String]();
            let dictionary = self.defaults().dictionary(forKey: defaultsKey);
            if let dictionary = dictionary,let variants =  dictionary[key] as? [String : String]{
                storedVariants = variants
            }
            return storedVariants
        }
}
//MARK: - SAFE MODE
extension FTUserDefaults {
    static func isInSafeMode() -> Bool {
        return UserDefaults.standard.bool(forKey: "safe_mode_Identifier")
    }
}
//MARK: - Hold to convert to shape
extension FTUserDefaults {
    static func setHoldToConvertToShapeForPen(_ isOn : Bool){
        self.defaults().setValue(isOn, forKey: "hold_to_convert_to_shape_identifier_pen")
    }
    static func isHoldToConvertToShapeOnForPen() -> Bool {
        return self.defaults().bool(forKey: "hold_to_convert_to_shape_identifier_pen")
    }
    static func setHoldToConvertToShapeForHighlighter(_ isOn : Bool){
        self.defaults().setValue(isOn, forKey: "hold_to_convert_to_shape_identifier_highlighter")
    }
    static func isHoldToConvertToShapeOnForHighlighter() -> Bool {
        return self.defaults().bool(forKey: "hold_to_convert_to_shape_identifier_highlighter")
    }
    static func setDrawStriaghtLinesOption(_ isOn : Bool){
        self.defaults().setValue(isOn, forKey: "draw_straight_lines_identifier")
    }
    static func isDrawStraightLinesOn() -> Bool {
        return self.defaults().bool(forKey: "draw_straight_lines_identifier")
    }
}

//MARK:- Zoom bar button on onScreenWritingVC
extension FTUserDefaults {
    static func setZoomBoxModeTo(_ isOn : Bool){
        self.defaults().setValue(isOn, forKey: "zoom_button_visibility_identifier")
    }
    static func isZoomBoxModeOn() -> Bool{
        return self.defaults().bool(forKey: "zoom_button_visibility_identifier")
    }
}

extension FTUserDefaults { // for saving last selected non collection type
    static func isInNonCollectionMode() -> Bool {
        return self.defaults().bool(forKey: NonCollectionModeKey)
    }
    static func setNonCollectionModeTo(_ isOn: Bool){
        self.defaults().setValue(isOn, forKey: NonCollectionModeKey)
    }
    static func setLastSelectedNonCollectionType(_ type:String){
        self.defaults().setValue(type, forKey: LastSelectedNonCollectionTypeKey)
    }
    static func lastSelectedNonCollectionType() -> String? {
       return  self.defaults().string(forKey: LastSelectedNonCollectionTypeKey)
    }
    static func setLastSelectedTag(_ type:String){
        self.defaults().setValue(type, forKey: LastSelectedTagKey)
    }
    static func lastSelectedTag() -> String? {
       return  self.defaults().string(forKey: LastSelectedTagKey)
    }
}

extension FTUserDefaults { // Saving this for Show or hide Home Get started section
    static func isFirstLaunch() -> Bool {
        return self.defaults().bool(forKey: isFirstLaunchKey)
    }
    static func setFirstLaunch(_ value:Bool) {
        return self.defaults().setValue(value, forKey: isFirstLaunchKey)
    }
}
