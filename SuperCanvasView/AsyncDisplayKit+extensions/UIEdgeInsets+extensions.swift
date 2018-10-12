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
    
    func top(_ inset: CGFloat) -> UIEdgeInsets {
        var mutable = self
        mutable.top = inset
        return mutable
    }
    
    mutating func bottom(_ inset: CGFloat) -> UIEdgeInsets {
        var mutable = self
        mutable.bottom = inset
        return mutable
    }
    
    mutating func left(_ inset: CGFloat) -> UIEdgeInsets {
        var mutable = self
        mutable.left = inset
        return mutable
    }
    
    mutating func right(_ inset: CGFloat) -> UIEdgeInsets {
        var mutable = self
        mutable.right = inset
        return mutable
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
