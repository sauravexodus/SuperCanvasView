//
//  Array+extension.swift
//  SuperCanvasView
//
//  Created by Vamsee Chamakura on 09/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import UIKit

extension Array where Element: UIImage {
    
    func mergeToSingleImage() -> UIImage? {

        let newImageWidth  = self.map { $0.size.width }.max() ?? 0
        let newImageHeight: CGFloat = self.reduce(0, { $0 + $1.size.height })
        let newImageSize = CGSize(width : newImageWidth, height: newImageHeight)

        UIGraphicsBeginImageContextWithOptions(newImageSize, false, UIScreen.main.scale)

        var y: CGFloat = 0
        self.forEach {
            $0.draw(at: CGPoint(x: 0,  y: y))
            y += $0.size.height
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
