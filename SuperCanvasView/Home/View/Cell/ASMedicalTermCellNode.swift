//
//  ASMedicalTermNodeCell.swift
//  SuperCanvasView
//
//  Created by Sourav Chandra on 07/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import SnapKit

final class ASMedicalTermCellNode: UIView {
    let titleLabel = UILabel().then {
        $0.textColor = .black
    }
    
    let canvasView = CanvasView().then {
        $0.backgroundColor = .clear
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func configure(with text: String?, and lines: [Line]) {
        titleLabel.text = text
        canvasView.lines = lines
        addSubview(titleLabel)
        addSubview(canvasView)
        titleLabel.snp.remakeConstraints { make in
            make.height.equalToSuperview()
            make.top.bottom.left.right.equalToSuperview()
        }
        canvasView.snp.remakeConstraints { make in
            make.height.equalToSuperview()
            make.top.bottom.left.right.equalToSuperview()
        }
    }
}
