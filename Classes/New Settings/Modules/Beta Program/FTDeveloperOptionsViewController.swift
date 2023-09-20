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
    #if DEBUG
    static var showOnScreenBorder: Bool = false
    #else
    static var showOnScreenBorder: Bool = false
    #endif
    static var bookScaleAnim = true
    static var showTileBorder: Bool = false
    static var showTileInfo: Bool = false
    static var enablePDFSelection: Bool = true
    static var textToStrokeWrapChar: Bool = false
    static var textToStrokeSnapToLineHeight: Bool = true
    static var cacheTextureTileImage: Bool = true

   fileprivate struct SliderOptions {
        let title: String
        let minValue: Float
        let maxValue: Float
        let value: Float
    }
}

class FTDeveloperOptionsViewController: UIViewController {

    //Laser
    @IBOutlet private weak var scaleView: FTDeveloperSliderView?
    @IBOutlet private weak var scaleDurationView: FTDeveloperSliderView?
    @IBOutlet private weak var fadeDurationView: FTDeveloperSliderView?
    @IBOutlet private weak var enablePDFSelection: UISwitch?

    //Metal
    @IBOutlet private weak var bgTilingSwitch: UISwitch?
    @IBOutlet private weak var offScreenRenderSwitch: UISwitch?

    //Local
    @IBOutlet private weak var onscreenBorderSwitch: UISwitch?
    @IBOutlet private weak var showTileBorderSwitch: UISwitch?
    @IBOutlet private weak var showTileInfoSwitch: UISwitch?

    //Book Open Anim
    @IBOutlet private weak var bookOpenAnimScale: UISwitch?
    @IBOutlet private weak var enablePremiumMode: UISwitch?

    @IBOutlet private weak var textToStrokeWrapChar: UISwitch?
    @IBOutlet private weak var textToStrokeSnapToLineHeight: UISwitch?
    
    @IBOutlet private weak var aiTokenOption: UIView?

    @IBOutlet weak var speedLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTilingDevOptions()
        configureLaserOptions()
        self.view.backgroundColor = UIColor.appColor(.formSheetBgColor)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNewNavigationBar(hideDoneButton: false,title: "🛠 Developer Options")
    }
    
    private func configureLaserOptions() {
        enablePDFSelection?.isOn = FTDeveloperOption.enablePDFSelection
        //Scale
        let scaleOptions = FTDeveloperOption.SliderOptions(title: "Scale", minValue: 0.0, maxValue: 1.0, value: Float(FTLaserAnimationValues.scale))
        scaleView?.configure(with: scaleOptions)
        scaleView?.valueUpdated = { value in
            FTLaserAnimationValues.scale = CGFloat(value)
        }

        //Scale duration
        let scaleDurationOptions = FTDeveloperOption.SliderOptions(title: "Scale Duration", minValue: 0.0, maxValue: 0.2, value: Float(FTLaserAnimationValues.scaleDuration))
        scaleDurationView?.configure(with: scaleDurationOptions)
        scaleDurationView?.valueUpdated = { value in
            FTLaserAnimationValues.scaleDuration = TimeInterval(value)
        }

        //Fade out duration
        let fadeOutDurationOptions = FTDeveloperOption.SliderOptions(title: "Fade Out Duration", minValue: 0.0, maxValue: 0.2, value: Float(FTLaserAnimationValues.fadeOutDuration))
        fadeDurationView?.configure(with: fadeOutDurationOptions)
        fadeDurationView?.valueUpdated = { value in
            FTLaserAnimationValues.fadeOutDuration = TimeInterval(value)
        }
    }

    private func configureTilingDevOptions() {
        //Metal
        bgTilingSwitch?.isOn = FTRenderConstants.USE_BG_TILING
        offScreenRenderSwitch?.isOn = FTRenderConstants.STOP_OFFSCREEN_RENDER

        //Local
        onscreenBorderSwitch?.isOn = FTDeveloperOption.showOnScreenBorder
        showTileBorderSwitch?.isOn = FTDeveloperOption.showTileBorder
        showTileInfoSwitch?.isOn = FTDeveloperOption.showTileInfo
        
        updateSwitches()
    }

    private func updateSwitches() {
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
    }
    
    @IBAction func togglePremiumMode(_ swicth: UISwitch) {
        FTIAPurchaseHelper.shared.isPremiumUser = swicth.isOn
    }
    
    // MARK:- Metal
    @IBAction func toggleBGTiling(swicth: UISwitch) {
        FTRenderConstants.USE_BG_TILING = swicth.isOn
        updateSwitches()
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

    @IBAction func clearRecents(sender: UIButton?) {
#if DEBUG || ADHOC
        FTRecentEntries.clearRecentList();
#endif
    }

    @IBAction func clearStarred(sender: UIButton?) {
#if DEBUG || ADHOC
        FTRecentEntries.clearStarredList();
#endif
    }

    @IBAction func resetAITokens(sender: UIButton?) {
#if !RELEASE
        UserDefaults.resetAITokens();
#endif
    }

    @IBAction func resetTapped(sender: UIButton) {
        FTLaserAnimationValues.reset()
        configureLaserOptions()
    }
    @IBAction func animationValueChanged(_ sender: UIStepper) {
        let value = sender.value
        print("Stepper value  \(value)")
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
