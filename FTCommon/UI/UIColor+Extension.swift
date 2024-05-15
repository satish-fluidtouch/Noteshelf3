//
//  File.swift
//  
//
//  Created by Narayana on 16/05/22.
//

import UIKit

public extension UIColor {
    func colorSpaceModel() -> CGColorSpaceModel {
        return self.cgColor.colorSpace!.model
    }

    static var ftTextLightGray : UIColor {
        return UIColor(named: "titleColor") ?? UIColor.systemGray
    }

    static var ftLightGray : UIColor {
        return UIColor(named: "toolColorInactive") ?? UIColor.systemGray
    }

    static var charcoalGrey : UIColor {
        return UIColor(named: "charcoalGrey") ?? UIColor.red;
    }

    static var charcoalGrey20Alpha : UIColor {
        return UIColor(named: "charcoalGrey-20-opacity") ?? UIColor.yellow;
    }

    static var color7f7f7f : UIColor {
        return UIColor(named: "7f7f7f") ?? UIColor.magenta;
    }

    func canProvideRGBComponents() -> Bool {
        switch (self.colorSpaceModel()) {
        case .rgb,
             .monochrome:
                return true
            default:
                return false
        }
    }

    func red(_ red: UnsafeMutablePointer<CGFloat>?, green: UnsafeMutablePointer<CGFloat>?, blue: UnsafeMutablePointer<CGFloat>?, alpha: UnsafeMutablePointer<CGFloat>?) -> Bool {
        let components = cgColor.components
        var r: CGFloat
        var g: CGFloat
        var b: CGFloat
        var a: CGFloat

        switch colorSpaceModel() {
            case .monochrome:
                b = components?[0] ?? 0.0
                g = b
                r = g
                a = components?[1] ?? 0.0
            case .rgb:
                r = components?[0] ?? 0.0
                g = components?[1] ?? 0.0
                b = components?[2] ?? 0.0
                a = components?[3] ?? 0.0
            default:
                return false
        }
        if let red = red {
            red.pointee = r
        }
        if let green = green {
            green.pointee = g
        }
        if let blue = blue {
            blue.pointee = b
        }
        if let alpha = alpha {
            alpha.pointee = a
        }
        return true
    }

    func hue(_ hue: UnsafeMutablePointer<CGFloat>?, saturation: UnsafeMutablePointer<CGFloat>?, brightness: UnsafeMutablePointer<CGFloat>?, alpha: UnsafeMutablePointer<CGFloat>?) -> Bool {

        var r = CGFloat()
        var g = CGFloat()
        var b = CGFloat()
        var a = CGFloat()
        if !red(&r, green: &g, blue: &b, alpha: &a) {
            return false
        }
        UIColor.red(r, green: g, blue: b, toHue: hue, saturation: saturation, brightness: brightness)
        if let alpha = alpha {
            alpha.pointee = a
        }
        return true
    }

    func red() -> CGFloat {
        assert(canProvideRGBComponents(), "Must be an RGB color to use -red")
        let c = cgColor.components
        return c?[0] ?? 0.0
    }

    func green() -> CGFloat {
        assert(canProvideRGBComponents(), "Must be an RGB color to use -green")
        let c = cgColor.components
        if colorSpaceModel() == CGColorSpaceModel.monochrome {
            return c?[0] ?? 0.0
        }
        return c?[1] ?? 0.0
    }

    func blue() -> CGFloat {
        assert(canProvideRGBComponents(), "Must be an RGB color to use -blue")
        let c = cgColor.components
        if colorSpaceModel() == CGColorSpaceModel.monochrome {
            return c?[0] ?? 0.0
        }
        return c?[2] ?? 0.0
    }

    var whiteComponent: CGFloat {
        assert(colorSpaceModel() == CGColorSpaceModel.monochrome, "Must be a Monochrome color to use -white")
        let c = cgColor.components
        return c?[0] ?? 0.0
    }

    func hue() -> CGFloat {
        assert(self.canProvideRGBComponents(), "Must be an RGB color to use -hue")
        var h:CGFloat = 0.0
        _ = self.hue(&h, saturation:nil, brightness:nil, alpha:nil)
        return h
    }

    func saturation() -> CGFloat {
        assert(self.canProvideRGBComponents(), "Must be an RGB color to use -saturation")
        var s:CGFloat = 0.0
        _ = self.hue(nil, saturation:&s, brightness:nil, alpha:nil)
        return s
    }

    func brightness() -> CGFloat {
        assert(self.canProvideRGBComponents(), "Must be an RGB color to use -brightness")
        var v:CGFloat = 0.0
        _ =  self.hue(nil, saturation:nil, brightness:&v, alpha:nil)
        return v
    }

    func alpha() -> CGFloat {
        return cgColor.alpha
    }

    func luminance() -> CGFloat {
        assert(self.canProvideRGBComponents(), "Must be a RGB color to use luminance")

        var r = CGFloat()
        var g = CGFloat()
        var b = CGFloat()
        _ = CGFloat()
        if !self.red(&r, green:&g, blue:&b, alpha:nil) {return 0.0}

        // http://en.wikipedia.org/wiki/Luma_(video)
        // Y = 0.2126 R + 0.7152 G + 0.0722 B

        return r*0.2126 + g*0.7152 + b*0.0722
    }

    func rgbHex() -> UInt32 {
        assert(canProvideRGBComponents(), "Must be a RGB color to use rgbHex")

        var r = CGFloat()
        var g = CGFloat()
        var b = CGFloat()
        var a = CGFloat()
        if !red(&r, green: &g, blue: &b, alpha: &a) {
            return 0
        }

        r = min(max(r, 0.0), 1.0)
        g = min(max(g, 0.0), 1.0)
        b = min(max(b, 0.0), 1.0)

        return UInt32(((Int(roundf(Float(r * 255)))) << 16) | ((Int(roundf(Float(g * 255)))) << 8) | (Int(roundf(Float((b * 255))))))
    }

    // MARK: Arithmetic operations

    func colorByLuminanceMapping() -> UIColor {
        return UIColor(white:self.luminance(), alpha:1.0)
    }

    func colorByMultiplyingByRed(red:CGFloat, green:CGFloat, blue:CGFloat, alpha:CGFloat) -> UIColor {
        assert(self.canProvideRGBComponents(), "Must be a RGB color to use arithmetic operations")

        var r = CGFloat()
        var g = CGFloat()
        var b = CGFloat()
        var a = CGFloat()
        if !self.red(&r, green:&g, blue:&b, alpha:&a) {
            return .red
        }
        return UIColor(red:max(0.0, min(1.0, r * red)),
                               green:max(0.0, min(1.0, g * green)),
                                blue:max(0.0, min(1.0, b * blue)),
                               alpha:max(0.0, min(1.0, a * alpha)))
    }

    func colorByAddingRed(red:CGFloat, green:CGFloat, blue:CGFloat, alpha:CGFloat) -> UIColor {
        assert(self.canProvideRGBComponents(), "Must be a RGB color to use arithmetic operations")

        var r = CGFloat()
        var g = CGFloat()
        var b = CGFloat()
        var a = CGFloat()
        if !self.red(&r, green:&g, blue:&b, alpha:&a) {
            return self
        }

        return UIColor(red:max(0.0, min(1.0, r + red)),
                               green:max(0.0, min(1.0, g + green)),
                                blue:max(0.0, min(1.0, b + blue)),
                               alpha:max(0.0, min(1.0, a + alpha)))
    }

    func colorByLighteningToRed(red:CGFloat, green:CGFloat, blue:CGFloat, alpha:CGFloat) -> UIColor {
        assert(self.canProvideRGBComponents(), "Must be a RGB color to use arithmetic operations")

        var r = CGFloat()
        var g = CGFloat()
        var b = CGFloat()
        var a = CGFloat()
        if !self.red(&r, green:&g, blue:&b, alpha:&a) {
            return self
        }
        return UIColor(red:max(r, red),
                               green:max(g, green),
                                blue:max(b, blue),
                               alpha:max(a, alpha))
    }

    func colorByDarkeningToRed(red:CGFloat, green:CGFloat, blue:CGFloat, alpha:CGFloat) -> UIColor {
       assert(self.canProvideRGBComponents(), "Must be a RGB color to use arithmetic operations")

       var r = CGFloat()
       var g = CGFloat()
       var b = CGFloat()
       var a = CGFloat()
       if !self.red(&r, green:&g, blue:&b, alpha:&a) {
            return self
       }
       return UIColor(red:min(r, red),
                               green:min(g, green),
                                blue:min(b, blue),
                               alpha:min(a, alpha))
    }

    // MARK: Complementary Colors, etc
    @objc func isLightColor() -> Bool {
        var white:CGFloat = 0
        self.getWhite(&white, alpha:nil)
        return (white >= 0.9)
    }
    @objc func isLightTemplateColor() -> Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let brightness =  0.2126 * red + 0.7152 * green + 0.0722 * blue
        return (brightness > 0.81)
      }
    // MARK: String utilities
    func stringFromColor() -> String {
        assert(self.canProvideRGBComponents(), "Must be an RGB color to use -stringFromColor")
        let result:String
        switch (self.colorSpaceModel()) {
        case .rgb:
           result = String(format:"{%0.3f, %0.3f, %0.3f, %0.3f}", self.red(), self.green(), self.blue(), self.alpha())
        case .monochrome:
           result = String(format:"{%0.3f, %0.3f}", self.whiteComponent, self.alpha())
        default:
            result = ""
        }
        return result
    }

    @objc func hexStringFromColor() -> String {
        return String(format: "%0.6X", UInt(rgbHex()))
    }

    // MARK: Class methods

    class func color(withRGBHex hex: UInt32) -> UIColor? {
        let r = Int((hex >> 16) & 0xff)
        let g = Int((hex >> 8) & 0xff)
        let b = Int(hex) & 0xff

        return UIColor(red: CGFloat(Double(r) / 255.0), green: CGFloat(Double(g) / 255.0), blue: CGFloat(Double(b) / 255.0), alpha: 1.0)
    }

    class func red(_ r: CGFloat, green g: CGFloat, blue b: CGFloat, toHue pH: UnsafeMutablePointer<CGFloat>?, saturation pS: UnsafeMutablePointer<CGFloat>?, brightness pV: UnsafeMutablePointer<CGFloat>?) {
        var h: CGFloat
        var s: CGFloat
        var v: CGFloat
        let maxVal = CGFloat(max(r, max(g, b)))
        let minVal = CGFloat(min(r, min(g, b)))
        v = maxVal
        s = (maxVal != 0.0) ? ((maxVal - minVal) / maxVal) : 0.0
        if s == 0.0 {
            h = 0.0
        } else {
            let rc = (maxVal - r) / (maxVal - minVal) // Distance of color from red
            let gc = (maxVal - g) / (maxVal - minVal) // Distance of color from green
            let bc = (maxVal - b) / (maxVal - minVal) // Distance of color from blue
            if r == maxVal {
                h = bc - gc // resulting color between yellow and magenta
            } else if g == maxVal {
                h = 2 + rc - bc // resulting color between cyan and yellow
            } else {
                 h = 4 + gc - rc // resulting color between magenta and cyan
            }
            h *= 60.0                                    // Convert to degrees
            if h < 0.0 {h += 360.0}                    // Make non-negative
        }
        if let pH = pH {
            pH.pointee = h
        }
        if let pS = pS {
            pS.pointee = s
        }
        if let pV = pV {
            pV.pointee = v
        }
    }

    convenience init(hexWithAlphaString: String) {
        let strings = hexWithAlphaString.split(separator: "-")
        let alpha: CGFloat;
        if strings.count >= 2 {
            let stringVal = String(strings[1]).trimmingCharacters(in: .whitespacesAndNewlines);
            let floatVal = Float(stringVal) ?? 1;
            alpha = CGFloat(floatVal);
        }
        else {
            alpha = 1.0;
        }

        let hexString: String = strings[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: "#", with: "");
        let scanner = Scanner(string: hexString)
        
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)
        
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }

    @objc convenience init(hexString: String?) {
        let scanner = Scanner(string: hexString ?? "")
        var hex = UInt64()
        scanner.scanHexInt64(&hex)
        let r = Int((hex >> 16) & 0xff)
        let g = Int((hex >> 8) & 0xff)
        let b = Int(hex) & 0xff
        let red   = CGFloat(Double(r) / 255.0)
        let green = CGFloat(Double(g) / 255.0)
        let blue  = CGFloat(Double(b) / 255.0)
        let alpha = 1.0
        self.init(red: red, green: green, blue: blue, alpha: CGFloat(alpha))
    }

    convenience init(hexString: String, alpha: CGFloat = 1.0) {
        let hexString: String = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        if (hexString.hasPrefix("#")) {
            scanner.currentIndex = hexString.index(hexString.startIndex, offsetBy:1)
        }
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }

    func isEqualTo(_ otherColor: UIColor) -> Bool {
        var red1: CGFloat = 0, green1: CGFloat = 0, blue1: CGFloat = 0, alpha1: CGFloat = 0
        var red2: CGFloat = 0, green2: CGFloat = 0, blue2: CGFloat = 0, alpha2: CGFloat = 0
        self.getRed(&red1, green: &green1, blue: &blue1, alpha: &alpha1)
        otherColor.getRed(&red2, green: &green2, blue: &blue2, alpha: &alpha2)
        return red1 == red2 && green1 == green2 && blue1 == blue2 && alpha1 == alpha2
    }

    class var headerColor: UIColor {
        return UIColor.label
    }
}
