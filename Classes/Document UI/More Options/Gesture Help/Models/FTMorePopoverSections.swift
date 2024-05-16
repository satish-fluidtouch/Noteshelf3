//
//  FTMorePopoverSections.swift
//  Noteshelf
//
//  Created by Narayana on 16/03/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

struct FTMorePopoverSections {
    
    private func customToolbar() -> [FTNotebookMoreOption] {
        return [FTCustomizeToolbarSetting()]
    }
    
    private func pageProperties(_ page: FTPageProtocol) -> [FTNotebookMoreOption] {
        var section = [FTNotebookMoreOption]()
        section.append(FTNotebookOptionRotate(with: page.rotationAngle))
        section.append(FTNotebookOptionChangeTemplate())
        section.append(FTNotebookOptionSaveAsTemplate())
        return section
    }

    private func otherProperties() -> [FTNotebookMoreOption] {
        var section = [FTNotebookMoreOption]()
     //   section.append(FTNotebookOptionGesture())
     //   section.append(FTNotebookOptionHelp())
        section.append(FTNotebookAddScrollingDirection())
#if !targetEnvironment(macCatalyst)
        if !UIDevice.current.isIphone() {
            section.append(FTNotebookStatusBarSetting(isEnabled: FTUserDefaults.defaults().showStatusBar))
            section.append(FTNotebookAddToStylus())
        }
#endif
        section.append(FTNotebookOptionSettings())
        return section
    }
        
    func noteBookProperties() -> [FTNotebookMoreOption] {
        var section = [FTNotebookMoreOption]()
        section.append(FTNotebookPassword())
#if !targetEnvironment(macCatalyst)
        section.append(FTNotebookAddToSiri())
        section.append(FTNotebookEverNoteSetting(isEnabled: false))
#endif
        section.append(FTNotebookOptionGetInfo())
        return section
    }
    
    func moreSections(_ page: FTPageProtocol) -> [[FTNotebookMoreOption]] {
        var settings:[[FTNotebookMoreOption]] = [[FTNotebookMoreOption]]()
        // First section
        let secondSection = pageProperties(page)
        if !secondSection.isEmpty {
            settings.append(secondSection)
        }
        
        let noteBooksection = noteBookProperties()
            settings.append(noteBooksection)
        
        
        // Second Section
        let thirdSection = otherProperties()
        settings.append(thirdSection)
        
        // Third Section
    #if !targetEnvironment(macCatalyst)
        let fourthSection = customToolbar()
        settings.append(fourthSection)
    #endif
        return settings;
    }
}
