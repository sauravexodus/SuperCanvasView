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
        $0.textAlignment = .center
        $0.sizeToFit()
    }
    
    let canvasView = CanvasView().then {
        $0.backgroundColor = .clear
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func configure(with text: String?, and lines: [Line]) {
        if let `text` = text, text.contains("Symptom") {
            self.backgroundColor = .red
        } else if let `text` = text, text.contains("Diagnosis") {
            self.backgroundColor = .blue
        } else {
            self.backgroundColor = .white
        }
        titleLabel.text = text ?? "Empty"
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
