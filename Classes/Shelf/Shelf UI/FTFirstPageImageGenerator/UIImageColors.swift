//
//  UIImageColors.swift
//  https://github.com/jathu/UIImageColors
//
//  Created by Jathu Satkunarajah (@jathu) on 2015-06-11 - Toronto
//

import UIKit

public struct UIImageColors {
    public var background: UIColor!
    public var primary: UIColor!
    public var secondary: UIColor!
    public var detail: UIColor!
}

public enum UIImageColorsQuality: CGFloat {
    case lowest = 50 // 50px
    case low = 100 // 100px
    case high = 250 // 250px
    case highest = 0 // No scale
}

fileprivate struct UIImageColorsCounter {
    let color: Double
    let count: Int
    init(color: Double, count: Int) {
        self.color = color
        self.count = count
    }
}

/*
    Extension on double that replicates UIColor methods. We DO NOT want these
    exposed outside of the library because they don't make sense outside of the
    context of UIImageColors.
*/
fileprivate extension Double {
    
    private var r: Double {
        return fmod(floor(self/1000000),1000000)
    }
    
    private var g: Double {
        return fmod(floor(self/1000),1000)
    }
    
    private var b: Double {
        return fmod(self,1000)
    }
    
    var isDarkColor: Bool {
        return (r*0.2126) + (g*0.7152) + (b*0.0722) < 127.5
    }
    
    var isBlackOrWhite: Bool {
        return (r > 232 && g > 232 && b > 232) || (r < 23 && g < 23 && b < 23)
    }
    
    func isDistinct(_ other: Double) -> Bool {
        let _r = self.r
        let _g = self.g
        let _b = self.b
        let o_r = other.r
        let o_g = other.g
        let o_b = other.b

        return (fabs(_r-o_r) > 63.75 || fabs(_g-o_g) > 63.75 || fabs(_b-o_b) > 63.75)
            && !(fabs(_r-_g) < 7.65 && fabs(_r-_b) < 7.65 && fabs(o_r-o_g) < 7.65 && fabs(o_r-o_b) < 7.65)
    }
    
    func with(minSaturation: Double) -> Double {
        // Ref: https://en.wikipedia.org/wiki/HSL_and_HSV
        
        // Convert RGB to HSV

        let _r = r/255
        let _g = g/255
        let _b = b/255
        var H, S, V: Double
        let M = fmax(_r,fmax(_g, _b))
        var C = M-fmin(_r,fmin(_g, _b))
        
        V = M
        S = V == 0 ? 0:C/V
        
        if minSaturation <= S {
            return self
        }
        
        if C == 0 {
            H = 0
        } else if _r == M {
            H = fmod((_g-_b)/C, 6)
        } else if _g == M {
            H = 2+((_b-_r)/C)
        } else {
            H = 4+((_r-_g)/C)
        }
        
        if H < 0 {
            H += 6
        }
        
        // Back to RGB
        
        C = V*minSaturation
        let X = C*(1-fabs(fmod(H,2)-1))
        var R, G, B: Double
        
        switch H {
        case 0...1:
            R = C
            G = X
            B = 0
        case 1...2:
            R = X
            G = C
            B = 0
        case 2...3:
            R = 0
            G = C
            B = X
        case 3...4:
            R = 0
            G = X
            B = C
        case 4...5:
            R = X
            G = 0
            B = C
        case 5..<6:
            R = C
            G = 0
            B = X
        default:
            R = 0
            G = 0
            B = 0
        }
        
        let m = V-C
        
        return (floor((R + m)*255)*1000000)+(floor((G + m)*255)*1000)+floor((B + m)*255)
    }
    
    func isContrasting(_ color: Double) -> Bool {
        let bgLum = (0.2126*r)+(0.7152*g)+(0.0722*b)+12.75
        let fgLum = (0.2126*color.r)+(0.7152*color.g)+(0.0722*color.b)+12.75
        if bgLum > fgLum {
            return 1.6 < bgLum/fgLum
        } else {
            return 1.6 < fgLum/bgLum
        }
    }
    
    var uicolor: UIColor {
        return UIColor(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1)
    }
    
    var pretty: String {
        return "\(Int(self.r)), \(Int(self.g)), \(Int(self.b))"
    }
}

