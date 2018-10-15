//
//  ASPageBreakNodeCell.swift
//  SuperCanvasView
//
//  Created by Sourav Chandra on 13/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import AsyncDisplayKit

final class ASPageBreakCellNode: ASCellNode {
    override init() {
        super.init()
        backgroundColor = .red
        style.preferredSize.height = 3
    }
}
