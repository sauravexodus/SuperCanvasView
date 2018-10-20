//
//  UIFont+extensions.swift
//  SuperCanvasView
//
//  Created by Vatsal Manot on 10/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import UIKit

enum PrintFontSetting {
    case compact
    case regular
    case comfortable
    
    static var current: PrintFontSetting = .comfortable
}

extension UIFont {
    func withPointSizeOffset(_ offset: CGFloat) -> UIFont {
        guard let result = UIFont(name: fontName, size: pointSize + offset) else {
            print("Something has gone horribly, horribly awry...")
            print("Recovering by returning original font")
            return self
        }
        
        return result
    }
}

extension UIFont {
    // Mirrored from values provided here: https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/typography/
    
    private class func preferredCompactPrintFont(forTextStyle style: UIFontTextStyle) -> UIFont {
        switch style {
        case .largeTitle:
            return UIFont.systemFont(ofSize: 32, weight: .regular)
        case .title1:
            return UIFont.systemFont(ofSize: 26, weight: .regular)
        case .title2:
            return UIFont.systemFont(ofSize: 20, weight: .regular)
        case .title3:
            return UIFont.systemFont(ofSize: 18, weight: .regular)
        case .headline:
            return UIFont.systemFont(ofSize: 15, weight: .regular)
        case .body:
            return UIFont.systemFont(ofSize: 15, weight: .regular)
        case .callout:
            return UIFont.systemFont(ofSize: 14, weight: .regular)
        case .subheadline:
            return UIFont.systemFont(ofSize: 13, weight: .regular)
        case .footnote:
            return UIFont.systemFont(ofSize: 12, weight: .regular)
        case .caption1:
            return UIFont.systemFont(ofSize: 11, weight: .regular)
        case .caption2:
            return UIFont.systemFont(ofSize: 11, weight: .regular)
        default:
            return UIFont.preferredRegularPrintFont(forTextStyle: style).withPointSizeOffset(-2)
        }
    }
    
    private class func preferredRegularPrintFont(forTextStyle style: UIFontTextStyle) -> UIFont {
        switch style {
        case .largeTitle:
            return UIFont.systemFont(ofSize: 34, weight: .regular)
        case .title1:
            return UIFont.systemFont(ofSize: 28, weight: .regular)
        case .title2:
            return UIFont.systemFont(ofSize: 22, weight: .regular)
        case .title3:
            return UIFont.systemFont(ofSize: 20, weight: .regular)
        case .headline:
            return UIFont.systemFont(ofSize: 17, weight: .regular)
        case .body:
            return UIFont.systemFont(ofSize: 17, weight: .regular)
        case .callout:
            return UIFont.systemFont(ofSize: 16, weight: .regular)
        case .subheadline:
            return UIFont.systemFont(ofSize: 15, weight: .regular)
        case .footnote:
            return UIFont.systemFont(ofSize: 13, weight: .regular)
        case .caption1:
            return UIFont.systemFont(ofSize: 12, weight: .regular)
        case .caption2:
            return UIFont.systemFont(ofSize: 11, weight: .regular)
        default:
            return UIFont.preferredFont(forTextStyle: style)
        }
    }
    
    private class func preferredComfortablePrintFont(forTextStyle style: UIFontTextStyle) -> UIFont {
        switch style {
        case .largeTitle:
            return UIFont.systemFont(ofSize: 38, weight: .regular)
        case .title1:
            return UIFont.systemFont(ofSize: 32, weight: .regular)
        case .title2:
            return UIFont.systemFont(ofSize: 26, weight: .regular)
        case .title3:
            return UIFont.systemFont(ofSize: 24, weight: .regular)
        case .headline:
            return UIFont.systemFont(ofSize: 21, weight: .regular)
        case .body:
            return UIFont.systemFont(ofSize: 21, weight: .regular)
        case .callout:
            return UIFont.systemFont(ofSize: 20, weight: .regular)
        case .subheadline:
            return UIFont.systemFont(ofSize: 19, weight: .regular)
        case .footnote:
            return UIFont.systemFont(ofSize: 17, weight: .regular)
        case .caption1:
            return UIFont.systemFont(ofSize: 16, weight: .regular)
        case .caption2:
            return UIFont.systemFont(ofSize: 15, weight: .regular)
        default:
            return UIFont.preferredRegularPrintFont(forTextStyle: style).withPointSizeOffset(2)
        }
    }
    
    class func preferredPrintFont(forTextStyle style: UIFontTextStyle) -> UIFont {
        switch PrintFontSetting.current {
        case .compact:
            return preferredCompactPrintFont(forTextStyle: style)
        case .regular:
            return preferredRegularPrintFont(forTextStyle: style)
        case .comfortable:
            return preferredComfortablePrintFont(forTextStyle: style)
        }
    }
}
