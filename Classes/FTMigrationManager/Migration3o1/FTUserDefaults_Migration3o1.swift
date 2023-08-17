//
//  FTUserDefaults_Migration3o1.swift
//  Noteshelf
//
//  Created by Amar on 05/09/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension FTUserDefaults : FTMigrateTo3o1 {
    func performMigrationTo3o1() -> Bool
    {
        let sharedDefaults = FTUserDefaults.defaults();
        let value = sharedDefaults.float(forKey: "migrationVersion");
        if(value < 3.1) {
            let keysToMigrate = self.keysToMigrate();
            keysToMigrate.forEach { (key) in
                let value = UserDefaults.standard.value(forKey: key);
                if(nil != value) {
                    sharedDefaults.setValue(value, forKey: key);
                    UserDefaults.standard.removeObject(forKey: key);
                }
            }
            sharedDefaults.set(3.1, forKey: "migrationVersion");
            sharedDefaults.synchronize();
            UserDefaults.standard.synchronize();
        }
        return true;
    }
    
    private func keysToMigrate() -> [String]
    {
        return ["Default_Default_Cover"
            ,"Default_Default_Paper"
            ,"Default_Default_Cover_Title"
            ,"Default_Default_Paper_Title"
            ,"QuickCreate_Default_Cover"
            ,"QuickCreate_Default_Paper"
            ,"QuickCreate_Default_Cover_Title"
            ,"QuickCreate_Default_Paper_Title"
            ,RandomCoverEnabledKey
            ,LastSelectedCollectionKey
            ,LastOpenedGroupKey
            ,LastOpenedDocumentKey
            ,RecentThemesKey
            ,"iCloudOn"
            ,"iCloudWasOn"
            ,"iCloudPrompted"
        ];
    }
}
