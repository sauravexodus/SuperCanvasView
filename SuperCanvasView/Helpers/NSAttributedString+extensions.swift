//
//  NSAttributedString+extensions.swift
//  SuperCanvasView
//
//  Created by Sourav Chandra on 12/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import UIKit

extension NSAttributedString {
    func height(withConstrainedWidth width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        
        return ceil(boundingBox.height)
    }
    
    var heightContrainedToA4: CGFloat {
        return height(withConstrainedWidth: PageSize.A4.width)
    }
}
