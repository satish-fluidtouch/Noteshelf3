//
//  FTNThemeCategory_UIExtension.swift
//  Noteshelf
//
//  Created by Naidu on 21/05/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension FTThemeCategory{
    func isMobile() -> Bool {
        return (categoryName == "Mobile" || categoryName == "Mobil" || categoryName == "Móvil" || categoryName == "モバイル" || categoryName == "手机" || categoryName == "手機");
    }
    func isTransparent() -> Bool {
        return (categoryName == "Transparent" || categoryName == "Trasparente" || categoryName == "Transparente" || categoryName == "透明" || categoryName == "透明" || categoryName == "透明");
    }
    func isAudio() -> Bool {
        return (categoryName == "Audio" || categoryName == "オーディオ" || categoryName == "音频" || categoryName == "聲音");
    }
}
