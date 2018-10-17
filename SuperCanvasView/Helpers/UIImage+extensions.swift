//
//  UIImage+extensions.swift
//  SuperCanvasView
//
//  Created by Vamsee Chamakura on 12/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    func padToPage(of height: CGFloat) -> UIImage {
        let diffInHeight = height - self.size.height
        if diffInHeight > 0 {
            UIGraphicsBeginImageContextWithOptions(CGSize(width: self.size.width, height: height), false, self.scale)
            UIGraphicsGetCurrentContext()
            let origin = CGPoint(x: 0, y: 0)
            self.draw(at: origin)
            let imageWithInsets = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return imageWithInsets ?? self
        }
        return self
    }
    
}
