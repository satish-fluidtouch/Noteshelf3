//  Copyright (c) 2017 9elements GmbH <contact@9elements.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit

protocol ColorPickerViewDelegate: AnyObject {
    func colorDidChange(_ color: UIColor)
}

/// The `ColorPickerView` provides a way to pick colors.
/// It contains three elements - a hue picker, a brightness and saturation picker and an alpha
/// picker. It has full support for wide colors.
@IBDesignable @objc(IMGLYColorPickerView) open class ColorPickerView: UIControl {

    // MARK: - Properties
    weak var delegate: ColorPickerViewDelegate?

    /// The currently selected color
    @IBInspectable public  var color: UIColor {
        get {
            
            let returnColor = UIColor(
                deviceDependentHue: CGFloat(huePickerView.pickedHue.value),
                saturation: CGFloat(saturationBrightnessPickerView.pickedSaturation.value),
                brightness: CGFloat(saturationBrightnessPickerView.pickedBrightness.value),
                alpha: alphaPickerView.pickedAlpha
            )
            return returnColor
        }

        set {
            if color != newValue {
                let hsb = newValue.hsb

                // Note: These values are actually in P3 color space now, so we can use them for `pickedHue`, `pickedBrightness` and `pickedSaturation` despite not matching types
                let p3HSB = newValue.convertedToP3Values.hsb
                
                //TODO:: FIX "Hue value is not correctly working in simulator"
                huePickerView.pickedHue = DisplayP3Value(p3HSB.hue.value)

                saturationBrightnessPickerView.displayedHue = hsb.hue
                saturationBrightnessPickerView.pickedBrightness = DisplayP3Value(p3HSB.brightness.value)
                saturationBrightnessPickerView.pickedSaturation = DisplayP3Value(p3HSB.saturation.value)

                var alpha: CGFloat = 0
                newValue.getWhite(nil, alpha: &alpha)
                alphaPickerView.displayedColor = newValue
                alphaPickerView.pickedAlpha = alpha

                updateMarkersToMatchColor()
            }
        }
    }

     let huePickerView = HuePickerView()
     let saturationBrightnessPickerView = SaturationBrightnessPickerView()
     let alphaPickerView = AlphaPickerView()
    var currentConstraints = [NSLayoutConstraint]()
    // MARK: - Initializers

    /// :nodoc:
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    /// :nodoc:
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        configureHuePickerView()
        configureSaturationBrightnessPickerView()
        configureAlphaPickerView()
        configureConstraints()
    }

    // MARK: - Configuration

    private func configureHuePickerView() {
        huePickerView.translatesAutoresizingMaskIntoConstraints = false
        huePickerView.layer.cornerRadius = 4.0
        huePickerView.addTarget(self, action: #selector(huePickerChanged(_:)), for: .valueChanged)
        addSubview(huePickerView)
    }

    private func configureSaturationBrightnessPickerView() {
        saturationBrightnessPickerView.layer.cornerRadius = 4.0
        saturationBrightnessPickerView.translatesAutoresizingMaskIntoConstraints = false
        saturationBrightnessPickerView.addTarget(self, action: #selector(saturationBrightnessPickerChanged(_:)), for: .valueChanged)
        addSubview(saturationBrightnessPickerView)
    }

    private func configureAlphaPickerView() {
        alphaPickerView.translatesAutoresizingMaskIntoConstraints = false
        alphaPickerView.addTarget(self, action: #selector(alphaPickerChanged(_:)), for: .valueChanged)
//        addSubview(alphaPickerView)
    }

    private func configureConstraints() {
        self.updateHueWidth(to: 76, andSpacing: 24)
    }
    func updateHueWidth(to width:CGFloat, andSpacing spacing:CGFloat){
        NSLayoutConstraint.deactivate(currentConstraints)
        
        var constraints = [NSLayoutConstraint]()
        let views = [
            "saturationBrightnessPickerView": saturationBrightnessPickerView,
            "huePickerView": huePickerView,
            //"alphaPickerView": alphaPickerView,
        ]
        
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[saturationBrightnessPickerView]-0-|", options: [], metrics: nil, views: views))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[huePickerView(==saturationBrightnessPickerView)]-0-|", options: [], metrics: nil, views: views))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "|-0-[saturationBrightnessPickerView]-\(spacing)-[huePickerView(\(width))]-0-|", options: [], metrics: nil, views: views))
        
        NSLayoutConstraint.activate(constraints)
        currentConstraints = constraints
    }
    // MARK: - UIView

    open override func layoutSubviews() {
        super.layoutSubviews()
        updateMarkersToMatchColor()
    }

    // MARK: - Actions

    @objc private func huePickerChanged(_ huePickerView: HuePickerView) {
        let color = self.color
        saturationBrightnessPickerView.displayedHue = ExtendedSRGBValue(huePickerView.pickedHue.value)
        alphaPickerView.displayedColor = color
        huePickerView.markerView.backgroundColor = UIColor.init(hue: CGFloat(huePickerView.pickedHue.value), saturation: 1, brightness: 1, alpha: 1.0)
        saturationBrightnessPickerView.markerView.backgroundColor = color

        sendActions(for: .valueChanged)
        self.delegate?.colorDidChange(self.color)
    }

    @objc private func alphaPickerChanged(_ alphaPickerView: AlphaPickerView) {
        sendActions(for: .valueChanged)
        self.delegate?.colorDidChange(self.color)
    }

    @objc private func saturationBrightnessPickerChanged(_ saturationBrightnessPicker: SaturationBrightnessPickerView) {
        alphaPickerView.displayedColor = color
        saturationBrightnessPicker.markerView.backgroundColor = color
        if color.hsb.hue.value != 0 && color.hsb.hue.value != 1 {
            huePickerView.markerView.backgroundColor = UIColor.init(hue: CGFloat(color.hsb.hue.value), saturation: 1, brightness: 1, alpha: 1.0)
        }
        
        saturationBrightnessPickerView.markerView.backgroundColor = color
        sendActions(for: .valueChanged)
        self.delegate?.colorDidChange(self.color)
    }

    // MARK: - Markers

    private func updateMarkersToMatchColor() {
        huePickerView.updateMarkerPosition()
        saturationBrightnessPickerView.updateMarkerPosition()
        alphaPickerView.updateMarkerPosition()
        huePickerView.markerView.backgroundColor = UIColor.init(hue: CGFloat(color.hsb.hue.value), saturation: 1, brightness: 1, alpha: 1.0)
        saturationBrightnessPickerView.markerView.backgroundColor = color
    }
}
