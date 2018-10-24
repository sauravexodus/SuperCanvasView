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
    
    func padToPage(of height: CGFloat, width: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, self.scale)
        UIGraphicsGetCurrentContext()
        UIColor.red.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: width, height: height))
        let origin = CGPoint(x: 0, y: 0)
        self.draw(at: origin)
        let imageWithInsets = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageWithInsets ?? self
    }
    
}
