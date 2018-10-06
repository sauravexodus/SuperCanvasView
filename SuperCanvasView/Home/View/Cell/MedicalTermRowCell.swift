//
//  MedicalTermRowCell.swift
//  SuperCanvasView
//
//  Created by Krishna C Aluru on 10/6/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import UIKit
import Reusable
import RxSwift

final class MedicalTermRowCell: UITableViewCell, Reusable {
    let titleLabel = UILabel().then {
        $0.textColor = .black
    }
    
    let canvasView = CanvasView().then {
        $0.backgroundColor = .clear
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func prepareForReuse() {
//        canvasView.clearForReuse()
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .white
        selectionStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with text: String?, and lines: [Line], height: Float) {
        titleLabel.text = text
        canvasView.lines = lines
        addSubview(titleLabel)
        addSubview(canvasView)
        titleLabel.snp.remakeConstraints { make in
            make.height.equalTo(height)
            make.top.bottom.left.right.equalToSuperview()
        }
        canvasView.snp.remakeConstraints { make in
            make.height.equalTo(height)
            make.top.bottom.left.right.equalToSuperview()
        }
    }
}
