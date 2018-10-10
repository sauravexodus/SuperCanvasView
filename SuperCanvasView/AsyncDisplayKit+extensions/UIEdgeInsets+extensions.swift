//
//  File.swift
//  SuperCanvasView
//
//  Created by Sourav Chandra on 10/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import UIKit

extension UIEdgeInsets {
    
    static func all(_ inset: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
    }
    
    mutating func top(_ inset: CGFloat) -> UIEdgeInsets {
        top = inset
        return self
    }
    
    mutating func bottom(_ inset: CGFloat) -> UIEdgeInsets {
        bottom = inset
        return self
    }
    
    mutating func left(_ inset: CGFloat) -> UIEdgeInsets {
        left = inset
        return self
    }
    
    mutating func right(_ inset: CGFloat) -> UIEdgeInsets {
        right = inset
        return self
    }
    
    static func top(_ inset: CGFloat) -> UIEdgeInsets {
        var insets: UIEdgeInsets = .zero
        insets.top = inset
        return insets
    }
    
    static func bottom(_ inset: CGFloat) -> UIEdgeInsets {
        var insets: UIEdgeInsets = .zero
        insets.bottom = inset
        return insets
    }
    
    static func left(_ inset: CGFloat) -> UIEdgeInsets {
        var insets: UIEdgeInsets = .zero
        insets.left = inset
        return insets
    }
    
    static func right(_ inset: CGFloat) -> UIEdgeInsets {
        var insets: UIEdgeInsets = .zero
        insets.right = inset
        return insets
    }
}
