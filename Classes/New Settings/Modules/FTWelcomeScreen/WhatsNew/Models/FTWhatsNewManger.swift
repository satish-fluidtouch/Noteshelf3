//
//  FTWhatsNewManger.swift
//  Noteshelf
//
//  Created by Siva on 10/11/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTWhatsNewViewSlide: Codable {
    var slideIdentifier: String!
    var isExpired: Bool!
    var slideShowPlace: String!
    
    init(item: String, isExpired: Bool, slideShowPlace: FTWhatsNewSlideShowPlace) {
        self.slideIdentifier = item
        self.isExpired = isExpired
        self.slideShowPlace = slideShowPlace.rawValue
    }
}

enum FTWhatsNewViewMode: String {
    case allSlides
    case singleSlide
}

@objc enum FTWhatsNewSlideShowPlace: Int {
    case onlySettings // used for First and last slides
    case shelf // shelf + setting
    case notebook // notebook + settings
    case any // any place + settings

    init?(rawValue: String) {
        switch rawValue {
            case "onlySettings":
                self = .onlySettings
            case "shelf":
                self = .shelf
            case "notebook":
                self = .notebook
            case "any":
                self = .any
            default:
                return nil
        }
    }
    
    public typealias RawValue = String

    public var rawValue: RawValue {
        switch self {
            case .onlySettings:
                return "onlySettings"
            case .shelf:
                return "shelf"
            case .notebook:
                return "notebook"
            case .any:
                return "any"
        }
    }
}

let persistenceKey = "FTWhatsNewViewSlides";

class FTWhatsNewManger: NSObject {

    static let shared = FTWhatsNewManger()
    var sourceType: FTSourceScreen = FTSourceScreen.regular
    var slideViewMode: FTWhatsNewViewMode = .allSlides

    @objc class func start() {
        let slides = [
            FTWhatsNewViewSlide(item: String(describing: FTWhatsNew2024PlannerController.classForCoder()), isExpired: false, slideShowPlace: .shelf),
            FTWhatsNewViewSlide(item: String(describing: FTWhatsNewUserPlannerController.classForCoder()), isExpired: false, slideShowPlace: .shelf),
        ]

        var hasNewSlides = false;
        let existingSlides = self.getSlides();
        for slide in slides {
            if let index = existingSlides.firstIndex(where: { $0.slideIdentifier == slide.slideIdentifier }) {
                slide.isExpired = existingSlides[index].isExpired;
            } else {
                hasNewSlides = true;
            }
        }
        if hasNewSlides {
            let userDefaults = UserDefaults.standard;
            userDefaults.removeObject(forKey: WhatsNewReminderTime);
            userDefaults.synchronize();
            FTWhatsNewManger.shared.sourceType = FTSourceScreen.regular
        }

        self.storeSlides(slides);
    }

    class func viewControllers(for source: FTSourceScreen = FTSourceScreen.regular, slideShowPlace: FTWhatsNewSlideShowPlace) -> [FTWhatsNewSlideViewController]! {
        let standardUserDefaults = UserDefaults.standard
        if let slidesData = standardUserDefaults.value(forKey: persistenceKey) as? Data, let slides = try? JSONDecoder().decode([FTWhatsNewViewSlide].self, from: slidesData) {
            FTWhatsNewManger.shared.sourceType = source
            let storyboard = UIStoryboard(name: "FTWhatsNew", bundle: nil)
            switch source {
            case .regular:
                var slidesRegular = [FTWhatsNewViewSlide]()
                let unexpiredSlides = slides.filter {  !$0.isExpired && ($0.slideShowPlace == slideShowPlace.rawValue || $0.slideShowPlace == FTWhatsNewSlideShowPlace.any.rawValue) }
                slidesRegular.append(contentsOf: unexpiredSlides)
                return slidesRegular.compactMap({ storyboard.instantiateViewController(withIdentifier: $0.slideIdentifier) as? FTWhatsNewSlideViewController })
                
            case .settings:
                var slidesWithStartEndSlides = [FTWhatsNewViewSlide]()
                slidesWithStartEndSlides.append(contentsOf: slides)
                return slidesWithStartEndSlides.compactMap({ storyboard.instantiateViewController(withIdentifier: $0.slideIdentifier) as? FTWhatsNewSlideViewController })
            }
        } else {
            return [FTWhatsNewSlideViewController]()
        }
    }

    class func setAsWelcomeScreenViewed() {
        let userDefaults = UserDefaults.standard;
        userDefaults.set(true, forKey: WelcomeScreenViewed);
        userDefaults.removeObject(forKey: WelcomeScreenReminderTime);
        userDefaults.synchronize();
    }

    class func showMeWelcomeScreenTomorrow() {
        let userDefaults = UserDefaults.standard;
        userDefaults.removeObject(forKey: WelcomeScreenViewed);
        let tomorrowInSeconds = Date().timeIntervalSince1970 + (24 * 60 * 60);
        userDefaults.set(tomorrowInSeconds, forKey: WelcomeScreenReminderTime);
        userDefaults.synchronize();
    }

    class func canShowWelcomeScreen(onViewController : UIViewController) -> Bool {
        if !FTFeatureConfigHelper.shared.isFeatureEnabled(.ShowOnboarding) {
            return false
        }
        let userDefaults = UserDefaults.standard;
        let nowInSeconds = Date().timeIntervalSince1970;
        let reminderTimeInSeconds = userDefaults.double(forKey: WelcomeScreenReminderTime);
        if !userDefaults.bool(forKey: WelcomeScreenViewed), nowInSeconds > reminderTimeInSeconds {
            return true;
        }
        return false;
    }

    @objc class func setAsWhatsNewViewed() {
        let userDefaults = UserDefaults.standard;
        userDefaults.removeObject(forKey: WhatsNewReminderTime);
        userDefaults.synchronize();

        let standardUserDefaults = UserDefaults.standard;
        if let slidesData = standardUserDefaults.value(forKey: persistenceKey) as? Data, let slides = try? JSONDecoder().decode([FTWhatsNewViewSlide].self, from: slidesData) {
            slides.forEach({ $0.isExpired = true });
            self.storeSlides(slides);
        }
    }

    @objc class func canShow(from controller:UIViewController, placeOfSlideShow: FTWhatsNewSlideShowPlace) -> Bool {
        guard UIDevice.current.userInterfaceIdiom == .pad, controller.isRegularClass() == true else { return false };

        if(!FTWhatsNewManger.shouldShowWhatsNew()) {
            return false;
        }
        let userDefaults = UserDefaults.standard;
        let nowInSeconds = Date().timeIntervalSince1970;
        let reminderTimeInSeconds = userDefaults.double(forKey: WhatsNewReminderTime);
        if self.hasUnExpiredAndRequiredSlides(placeOfSlideShow: placeOfSlideShow), nowInSeconds > reminderTimeInSeconds {
            return true;
        }
        return false;
    }

    // MARK: - Private methods
    private class func getSlides() -> [FTWhatsNewViewSlide] {
        let standardUserDefaults = UserDefaults.standard;
        if let slidesData = standardUserDefaults.value(forKey: persistenceKey) as? Data, let slides = try? JSONDecoder().decode([FTWhatsNewViewSlide].self, from: slidesData) {
            return slides;
        } else {
            return [FTWhatsNewViewSlide]();
        }
    }

     class func storeSlides(_ slides: [FTWhatsNewViewSlide]) {
        let standardUserDefaults = UserDefaults.standard;
        if let slidesData = try? JSONEncoder().encode(slides) {
            standardUserDefaults.set(slidesData, forKey: persistenceKey);
        }
        standardUserDefaults.synchronize();
    }

    private class func hasUnExpiredAndRequiredSlides(placeOfSlideShow: FTWhatsNewSlideShowPlace) -> Bool {
        let standardUserDefaults = UserDefaults.standard;
        if let slidesData = standardUserDefaults.value(forKey: persistenceKey) as? Data, let slides = try? JSONDecoder().decode([FTWhatsNewViewSlide].self, from: slidesData) {
            return !slides.filter({ !$0.isExpired && ($0.slideShowPlace == placeOfSlideShow.rawValue || $0.slideShowPlace == FTWhatsNewSlideShowPlace.any.rawValue) }).isEmpty
        } else {
            return false
        }
    }

    @objc class func shouldShowWhatsNew() -> Bool {
        return false;
    }
}
