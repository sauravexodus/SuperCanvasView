//
//  PageSize.swift
//  SuperCanvasView
//
//  Created by Sourav Chandra on 12/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import UIKit

enum PageSize {
    case A4
    
    var height: CGFloat {
        switch self {
        case .A4: return 842
        }
    }
    
    var width: CGFloat {
        switch self {
        case .A4: return 595
        }
    }
    
    var size: CGSize {
        return CGSize(width: width, height: height)
    }
}
