//
//  FTBlurPresenterController.swift
//  Noteshelf
//
//  Created by Narayana on 19/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTBlurPresenterController: FTBasePenRackViewController {

    override class var identifier: String {
        "FTBlurPresenterController"
    }

    class override var regularContentSize: CGSize {
        CGSize(width: 320, height: 300)
    }

    override class var compactContentSize: CGSize {
        CGSize(width: 375, height: 300)
    }

    var type: FTRackType {
        return .shape
    }

    // Just adding for trail version
    var blurStyleStr: String = "dark"
    var blurAlpha: CGFloat = 0.1
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var blurStyleButton: UIButton!

    public override func viewDidLoad() {
        super.viewDidLoad()
        // trail version changes
        self.slider.addTarget(self, action: #selector(self.sliderValueDidChange(_:)), for: .valueChanged)
        if let blurStr = UserDefaults.standard.value(forKey: "BlurStyleString") as? String, let alpha = UserDefaults.standard.value(forKey: "BlurAlpha") as? CGFloat {
            self.blurStyleStr = blurStr
            self.blurAlpha = alpha
        } else {
            UserDefaults.standard.setValue(blurStyleStr, forKey: "BlurStyleString")
            UserDefaults.standard.setValue(blurAlpha, forKey: "BlurAlpha")
        }
        self.slider.value = Float(self.blurAlpha)
        self.updateBlurStyleTitle()
    }

    // Just adding for trail version
    @objc func sliderValueDidChange(_ sender:UISlider!) {
        self.blurAlpha = CGFloat(sender.value)
        UserDefaults.standard.set(self.blurAlpha, forKey: "BlurAlpha")
        self.updateBlurStyleTitle()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "FTBlurTestNotify"), object: self.view.window, userInfo: nil)
    }

    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let vc = segue.destination as? FTBlurSelectionController {
            vc.delegate = self
        }
    }
}

// Just adding for trail version
extension FTBlurPresenterController: FTBlurSelectionDelegate {
    func didSelectBlurStyle(string: String) {
        self.blurStyleStr = string
        UserDefaults.standard.setValue(self.blurStyleStr, forKey: "BlurStyleString")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "FTBlurTestNotify"), object: self.view.window, userInfo: nil)
        self.updateBlurStyleTitle()
    }

    private func updateBlurStyleTitle() {
        let roundedAlpha = self.blurAlpha.roundToDecimal(1)
        self.blurStyleButton.setTitle(self.blurStyleStr + " " + "\(roundedAlpha)", for: .normal)
    }
}
