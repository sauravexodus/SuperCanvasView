//
//  PageSize.swift
//  SuperCanvasView
//
//  Created by Sourav Chandra on 12/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import UIKit

enum PageSize: Int {
    
    case A4
    case A5
    
    var height: CGFloat {
        switch self {
        case .A4: return 842
        case .A5: return 595
        }
    }
    
    var width: CGFloat {
        switch self {
        case .A4: return 595
        case .A5: return 421
        }
    }
    
    var size: CGSize {
        return CGSize(width: width, height: height)
    }
    
    static var selectedPage: PageSize {
        get { return PageSize(rawValue: UserDefaults.standard.integer(forKey: "SelectedPageSize")) ?? .A4 }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "SelectedPageSize") }
    }
}
