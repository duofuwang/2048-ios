import UIKit

enum Theme: String {
    case holo = "1"
    case dark = "2"
    case classic = "3"

    static var current: Theme {
        Theme(rawValue: UserDefaults.standard.string(forKey: "pref_theme") ?? "1") ?? .holo
    }

    var backgroundColor: UIColor {
        switch self {
        case .holo: return UIColor(hex: 0xE5E5E5)
        case .dark: return UIColor(hex: 0x4D4D4D)
        case .classic: return UIColor(hex: 0xFAF8EF)
        }
    }

    var scoreColor: UIColor {
        self == .dark ? .white : UIColor(hex: 0x4D4D4D)
    }

    func cellColor(for value: Int) -> UIColor {
        switch self {
        case .classic:
            switch value {
            case 0: return UIColor(hex: 0xD6CDC4)
            case 2: return UIColor(hex: 0xEEE4DA)
            case 4: return UIColor(hex: 0xEDE0C8)
            case 8: return UIColor(hex: 0xF2B179)
            case 16: return UIColor(hex: 0xF59563)
            case 32: return UIColor(hex: 0xF67C5F)
            case 64: return UIColor(hex: 0xF65E3B)
            case 128: return UIColor(hex: 0xEDCF72)
            case 256: return UIColor(hex: 0xEDCC61)
            case 512: return UIColor(hex: 0xEDC850)
            case 1024: return UIColor(hex: 0xEDC53F)
            case 2048: return UIColor(hex: 0xEDC22E)
            default: return UIColor(hex: 0x3C3A32)
            }
        case .holo, .dark:
            switch value {
            case 0: return UIColor(hex: 0x6A6A6A)
            case 2: return UIColor(hex: 0x33B5E5)
            case 4: return UIColor(hex: 0x0099CC)
            case 8: return UIColor(hex: 0xAA66CC)
            case 16: return UIColor(hex: 0x9933CC)
            case 32: return UIColor(hex: 0x99CC00)
            case 64: return UIColor(hex: 0x669900)
            case 128: return UIColor(hex: 0xFFBB33)
            case 256: return UIColor(hex: 0xFF8800)
            case 512: return UIColor(hex: 0xFF4444)
            case 1024: return UIColor(hex: 0xCC0000)
            case 2048: return UIColor(hex: 0x000000)
            default: return UIColor(hex: 0xA2430A)
            }
        }
    }

    func tileTextColor(for value: Int) -> UIColor {
        if self == .classic && value < 8 {
            return UIColor(hex: 0x776E65)
        }
        return UIColor(hex: 0xF9F6F2)
    }
}

extension UIColor {
    convenience init(hex: Int) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
