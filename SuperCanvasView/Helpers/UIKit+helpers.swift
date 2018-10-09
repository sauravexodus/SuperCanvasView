//
//  UIKit+helpers.swift
//  SuperCanvasView
//
//  Created by Vatsal Manot on 10/9/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import UIKit

extension Float {
    var cgFloat: CGFloat {
        return CGFloat(self)
    }
}

extension CGSize {
    init(width: Float, height: Float) {
        self.init(width: CGFloat(width), height: CGFloat(height))
    }
}
