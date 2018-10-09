//
//  ASMedicalTermNodeCell.swift
//  SuperCanvasView
//
//  Created by Sourav Chandra on 07/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import AsyncDisplayKit

final class ASMedicalTermCellNode: UIView {
    
    let titleLabel = UILabel().then {
        $0.textColor = .black
    }
    
    let canvasView = CanvasView().then {
        $0.backgroundColor = .clear
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    let editMedicalTermButton = UIButton().then {
        $0.setTitle("Edit", for: .normal)
        $0.setTitleColor(.gray, for: .normal)
    }
    
    let deleteMedicalTermButton = UIButton().then {
        $0.setTitle("Delete", for: .normal)
        $0.setTitleColor(.gray, for: .normal)
    }
    
    func configure(with text: String?, and lines: [Line]) {
        titleLabel.text = text
        canvasView.lines = lines
        addSubview(titleLabel)
        addSubview(canvasView)
        addSubview(editMedicalTermButton)
        addSubview(deleteMedicalTermButton)
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
