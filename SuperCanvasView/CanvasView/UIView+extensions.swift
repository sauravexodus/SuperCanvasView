//
//  UIView+extensions.swift
//  SuperCanvasView
//
//  Created by Sourav Chandra on 10/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    var frameInDisplay: CGRect {
        var frame = self.frame
        
        guard let superviewFrame = superview?.frame else {
            return frame
        }
        
        if frame.origin.x > 0 {
            let xExtension = (frame.origin.x + frame.size.width) - superviewFrame.width
            if xExtension > 0 {
                frame.size.width = superviewFrame.width - frame.origin.x
            }
        } else if frame.origin.x < 0 {
            let widthInDisplay = frame.size.width + frame.origin.x
            frame.size.width = min(widthInDisplay, superviewFrame.width)
        } else {
            frame.size.width = min(frame.width, superviewFrame.width)
        }
        
        if frame.origin.y > 0 {
            let yExtension = (frame.origin.y + frame.size.height) - superviewFrame.height
            if yExtension > 0 {
                frame.size.height = superviewFrame.height - frame.origin.y
            }
        } else if frame.origin.y < 0 {
            let heightInDisplay = frame.size.height + frame.origin.y
            frame.size.height = min(heightInDisplay, superviewFrame.height)
        } else {
            frame.size.height = min(frame.height, superviewFrame.height)
        }
        
        return frame
    }
}
