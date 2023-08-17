//
//  FTPreviewSizeHelper.swift
//  FTNewNotebook
//
//  Created by Narayana on 31/03/23.
//

import UIKit
import AVFoundation

class FTPreviewSizeHelper: NSObject {
// Covers
    private var hMargin: CGFloat = 44.0
    private var vMargin: CGFloat = 44.0
    private let maxPreviewWidth: CGFloat = 509.0
    private let maxPreviewHeight: CGFloat = 678.0

    private func getAvailableSize(in controller: FTChooseCoverViewController) -> CGSize {
        let viewSize = controller.view.frame.size
        var availableSize = viewSize
        if controller.isRegularClass() && availableSize.width > availableSize.height  {
            hMargin = 76.0
        }
        availableSize.width -= 2.0 * hMargin
        availableSize.height -= 2.0 * vMargin

        // Panel Height
        let panelHeight = controller.getPanelHeight()
        availableSize.height -= (panelHeight + controller.view.safeAreaInsets.top)
        return availableSize
    }

    func getCoverPreviewSize(from controller: FTChooseCoverViewController) -> CGSize {
        let availSize = self.getAvailableSize(in: controller)
        let availWidth = availSize.width
        let availHeight = availSize.height

        var reqPreviewSize: CGSize = .zero
        if availWidth < availHeight {
            if availWidth > maxPreviewWidth {
                reqPreviewSize.width = maxPreviewWidth
            } else {
                reqPreviewSize.width = min(0.75 * maxPreviewWidth, availWidth)
            }
            reqPreviewSize.height = (reqPreviewSize.width * 4.0/3.0)

            // tuning to avoid padding issues
            if (reqPreviewSize.height > availHeight) || (reqPreviewSize.height > maxPreviewHeight) {
                reqPreviewSize.height = 0.75 * availHeight
                reqPreviewSize.width = (reqPreviewSize.height * 3.0/4.0)
            }
        } else {
            if availHeight > maxPreviewHeight {
                reqPreviewSize.height = maxPreviewHeight
            } else {
                reqPreviewSize.height = min(maxPreviewHeight * 0.75, availHeight)
            }
            reqPreviewSize.width = (reqPreviewSize.height * 3.0/4.0)

            // tuning to avoid padding issues
            if (reqPreviewSize.width > availWidth) || (reqPreviewSize.width > maxPreviewWidth) {
                reqPreviewSize.width = 0.75 * availWidth
                reqPreviewSize.height = (reqPreviewSize.width * 4.0/3.0)
            }
        }
        return reqPreviewSize
    }
}
