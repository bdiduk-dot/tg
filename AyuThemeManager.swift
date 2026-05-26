import UIKit

@objc public class AyuThemeManager: NSObject {
    @objc public static let shared = AyuThemeManager()
    
    // Preset themes representing high-quality premium color tones
    @objc public static let themePresets: [[String: String]] = [
        ["name": "Gold Premium", "hsl": "45,95%,50%"],
        ["name": "Neon Regress", "hsl": "180,100%,45%"],
        ["name": "Velvet Royal", "hsl": "280,75%,45%"],
        ["name": "Cyberpunk Red", "hsl": "340,90%,50%"],
        ["name": "Eco Mint", "hsl": "145,65%,45%"],
        ["name": "Dynamic System", "hsl": "system"]
    ]
    
    private override init() {
        super.init()
    }
    
    // Generates a UIColor using HSL color space parameters
    public func colorFromHSL(h: CGFloat, s: CGFloat, l: CGFloat, alpha: CGFloat = 1.0) -> UIColor {
        return UIColor(hue: h / 360.0, saturation: s / 100.0, brightness: l / 100.0, alpha: alpha)
    }
    
    // Parse HSL string (e.g. "45,95%,50%") and return custom colors
    @objc public func getColorForComponent(_ type: String, rawHSL: String) -> UIColor {
        var hue: CGFloat = 200.0
        var sat: CGFloat = 80.0
        var light: CGFloat = 50.0
        
        if rawHSL == "system" {
            // Material You styled - extract from iOS 12+ system tint
            return tintColorForSystem(type)
        }
        
        let components = rawHSL.components(separatedBy: ",")
        if components.count == 3 {
            hue = CGFloat(Double(components[0].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 200.0)
            let satStr = components[1].replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            sat = CGFloat(Double(satStr) ?? 80.0)
            let lightStr = components[2].replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            light = CGFloat(Double(lightStr) ?? 50.0)
        }
        
        switch type {
        case "primary":
            return colorFromHSL(h: hue, s: sat, l: light)
        case "background":
            // Beautiful slate dark background for primary colors
            return colorFromHSL(h: hue, s: 15.0, l: 8.0)
        case "card":
            // Translucent card tint
            return colorFromHSL(h: hue, s: 12.0, l: 14.0)
        case "accent":
            // Complementary vibrant color for micro-animations
            let compHue = (hue + 180.0).truncatingRemainder(dividingBy: 360.0)
            return colorFromHSL(h: compHue, s: sat, l: light)
        case "text":
            return colorFromHSL(h: hue, s: 10.0, l: 95.0)
        case "subtext":
            return colorFromHSL(h: hue, s: 8.0, l: 65.0)
        default:
            return colorFromHSL(h: hue, s: sat, l: light)
        }
    }
    
    private func tintColorForSystem(_ type: String) -> UIColor {
        let tint = UIView().tintColor ?? UIColor.systemBlue
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        tint.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        let hue = h * 360.0
        switch type {
        case "primary":
            return tint
        case "background":
            return colorFromHSL(h: hue, s: 10.0, l: 8.0)
        case "card":
            return colorFromHSL(h: hue, s: 8.0, l: 14.0)
        case "accent":
            return colorFromHSL(h: (hue + 180.0).truncatingRemainder(dividingBy: 360.0), s: 85.0, l: 50.0)
        case "text":
            return .white
        case "subtext":
            return .lightGray
        default:
            return tint
        }
    }
}
