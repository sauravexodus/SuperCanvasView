//
//  ASMedicalSectionHeaderCellNode.swift
//  SuperCanvasView
//
//  Created by Krishna C Aluru on 10/9/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import UIKit
import AsyncDisplayKit
import SnapKit

final class ASMedicalSectionHeaderCellNode: UIView {
    let titleLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 18)
        $0.textColor = .black
    }
    
    func configure(with text: String) {
        titleLabel.text = text
        titleLabel.backgroundColor = .red
        addSubview(titleLabel)
        titleLabel.snp.remakeConstraints { make in
            make.height.equalTo(32)
            make.top.bottom.left.right.equalToSuperview()
        }
    }
}

