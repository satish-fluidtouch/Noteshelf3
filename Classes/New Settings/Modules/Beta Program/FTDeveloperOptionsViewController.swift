//
//  FTDeveloperOptionsViewController.swift
//  Noteshelf
//
//  Created by Akshay on 24/12/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

struct FTDeveloperOption {
    // --------------------------------- //
    // Never ever change these values without consent.
    // USe Debug/Beta macro if required
    static var bookScaleAnim = true
    static var cacheTextureTileImage: Bool = false
    static var enablePDFSelection: Bool = true
    static var textToStrokeWrapChar: Bool = false
    static var textToStrokeSnapToLineHeight: Bool = true
    static var useQuickLookThumbnailing: Bool = true

    static var showOnScreenBorder: Bool = false
    static var showTileBorder: Bool = false
    static var showTileInfo: Bool = false
    // --------------------------------- //

   fileprivate struct SliderOptions {
        let title: String
        let minValue: Float
        let maxValue: Float
        let value: Float
    }
}

#if !NOTESHELF_ACTION
class FTDeveloperOptionsViewController: UIViewController {
    @IBOutlet private weak var enablePDFSelection: UISwitch?
    @IBOutlet private weak var offScreenRenderSwitch: UISwitch?
    @IBOutlet private weak var onscreenBorderSwitch: UISwitch?
    @IBOutlet weak var whatsNewStatusSwitch: UISwitch!
    @IBOutlet private weak var showTileBorderSwitch: UISwitch?
    @IBOutlet weak var whatsNewStatusLabel: UILabel!
    @IBOutlet private weak var showTileInfoSwitch: UISwitch?
    @IBOutlet private weak var bookOpenAnimScale: UISwitch?
    @IBOutlet private weak var enablePremiumMode: UISwitch?
    @IBOutlet private weak var useQLThumbnail: UISwitch?

    @IBOutlet private weak var textToStrokeWrapChar: UISwitch?
    @IBOutlet private weak var textToStrokeSnapToLineHeight: UISwitch?

    @IBOutlet weak var speedLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        updateSwitches()
        self.view.backgroundColor = UIColor.appColor(.formSheetBgColor)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNewNavigationBar(hideDoneButton: false,title: "🛠 Developer Options")
    }

    private func updateSwitches() {

        offScreenRenderSwitch?.isOn = FTRenderConstants.STOP_OFFSCREEN_RENDER
        enablePDFSelection?.isOn = FTDeveloperOption.enablePDFSelection

        //Local
        onscreenBorderSwitch?.isOn = FTDeveloperOption.showOnScreenBorder
        showTileBorderSwitch?.isOn = FTDeveloperOption.showTileBorder
        showTileInfoSwitch?.isOn = FTDeveloperOption.showTileInfo

        if FTRenderConstants.USE_BG_TILING {
            showTileBorderSwitch?.isEnabled = true
        } else {
            FTDeveloperOption.showTileBorder = false
            FTDeveloperOption.showTileInfo = false

            showTileBorderSwitch?.isOn = false
            showTileInfoSwitch?.isOn = false
            
            showTileBorderSwitch?.isEnabled = false
            showTileInfoSwitch?.isEnabled = false
        }
        
        bookOpenAnimScale?.isOn = FTDeveloperOption.bookScaleAnim
        textToStrokeWrapChar?.isOn = FTDeveloperOption.textToStrokeWrapChar
        enablePremiumMode?.isOn = FTIAPurchaseHelper.shared.isPremiumUser
        textToStrokeSnapToLineHeight?.isOn = FTDeveloperOption.textToStrokeWrapChar
        useQLThumbnail?.isOn = FTDeveloperOption.useQuickLookThumbnailing
        whatsNewStatusSwitch.isOn = FTUserDefaults.defaults().statusBarwhatsNewSwitch
    }
    
    @IBAction func togglePremiumMode(_ swicth: UISwitch) {
        FTIAPurchaseHelper.shared.isPremiumUser = swicth.isOn
    }
    
    // MARK:- Metal
    @IBAction func toggleBGTiling(swicth: UISwitch) {
        FTRenderConstants.USE_BG_TILING = swicth.isOn
        updateSwitches()
    }

    @IBAction func onWhatsNewToggleChanged(_ sender: UISwitch) {
        FTUserDefaults.defaults().statusBarwhatsNewSwitch = sender.isOn
    }
    
    @IBAction func toggleOffScreenRender(swicth: UISwitch) {
        FTRenderConstants.STOP_OFFSCREEN_RENDER = swicth.isOn
    }

    // MARK:- local
    @IBAction func toggleOnscreenBorder(swicth: UISwitch) {
        FTDeveloperOption.showOnScreenBorder = swicth.isOn
    }

    @IBAction func toggleTileBorder(swicth: UISwitch) {
        FTDeveloperOption.showTileBorder = swicth.isOn
    }

    @IBAction func toggleTileInfo(swicth: UISwitch) {
        FTDeveloperOption.showTileInfo = swicth.isOn
    }

    @IBAction func toggleBookOpenScaleAnim(swicth: UISwitch) {
        FTDeveloperOption.bookScaleAnim = swicth.isOn
    }

    @IBAction func toggleTextToStrokeCharWrap(swicth: UISwitch) {
        FTDeveloperOption.textToStrokeWrapChar = swicth.isOn
    }

    @IBAction func toggleTextToStrokeSnapToLineHeight(swicth: UISwitch) {
        FTDeveloperOption.textToStrokeSnapToLineHeight = swicth.isOn
    }

    @IBAction func toggleEnablePDFSelection(swicth: UISwitch) {
        FTDeveloperOption.enablePDFSelection = swicth.isOn
    }

    @IBAction func toggleQLThumbnail(swicth: UISwitch) {
        FTDeveloperOption.useQuickLookThumbnailing = swicth.isOn
    }

    @IBAction func resetAITokens(sender: UIButton?) {
#if DEBUG
        FTNoteshelfAITokenManager.shared.resetAITokens();
#endif
    }

    @IBAction func resetCacheFolder(sender: UIButton?) {
        try? FileManager.default.removeItem(at: FTDocumentCache.shared.sharedCacheFolderURL)
    }

    @IBAction func animationValueChanged(_ sender: UIStepper) {
        let value = sender.value
        speedLabel.text = "Animation Duration \(value)"
        AnimationValue.animatedValue = value
    }
}

class FTDeveloperSliderView: UIView {

    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var minValueLabel: UILabel?
    @IBOutlet weak var currentValueLabel: UILabel?
    @IBOutlet weak var maxValueLabel: UILabel?

    @IBOutlet weak var slider: UISlider?

    fileprivate var valueUpdated: ((_ value: Float) -> Void)?

    fileprivate func configure(with options: FTDeveloperOption.SliderOptions) {

        titleLabel?.text = options.title

        minValueLabel?.text = String(format: "%0.3f", options.minValue)
        currentValueLabel?.text = String(format: "%0.3f", options.value)
        maxValueLabel?.text = String(format: "%0.3f", options.maxValue)
        slider?.minimumValue = options.minValue
        slider?.maximumValue = options.maxValue
        slider?.value  = options.value

    }

    @IBAction func sliderValueChanged(_ slider: UISlider) {
        currentValueLabel?.text = String(format: "%0.3f", slider.value)
        valueUpdated?(slider.value)
    }
}
#endif
