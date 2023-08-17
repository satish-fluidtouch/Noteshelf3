//
//  FTLocalizedString.swift
//  Noteshelf
//
//  Created by Amar on 05/08/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

func FTWhatsNewLocalizedString(_ key : String,comment : String?) -> String
{
    return NSLocalizedString(key,
                             tableName: "WhatsNewLocalizable",
                             bundle: Bundle.main,
                             value: "",
                             comment: comment ?? "");
}

func FTWelcomeLocalizedString(_ key : String,comment : String?) -> String
{
    return NSLocalizedString(key,
                             tableName: "WelcomeLocalizable",
                             bundle: Bundle.main,
                             value: "",
                             comment: comment ?? "");
}

func FTLanguageLocalizedString(_ key : String,comment : String?) -> String
{
    return NSLocalizedString(key,
                             tableName: "MyScriptLanguageLocalizable",
                             bundle: Bundle.main,
                             value: "",
                             comment: comment ?? "");
}

func FTBetaProgramLocalizedString(_ key : String,comment : String?) -> String
{
    return NSLocalizedString(key,
                             tableName: "BetaProgramLocalizable",
                             bundle: Bundle.main,
                             value: "",
                             comment: comment ?? "");
}

func FTMacWelcomeScreenLocalizedString(_ key : String,comment : String?) -> String
{
    return NSLocalizedString(key,
                             tableName: "FTWelcomeScreenMacLocalized",
                             bundle: Bundle.main,
                             value: "",
                             comment: comment ?? "");
}

func FTDiaryGeneratorLocalizedString(_ key: String, comment: String?) -> String {
    return NSLocalizedString(key,
                             tableName: "Localizable",
                             bundle: Bundle.main,
                             value: "", comment: comment ?? "")
}
