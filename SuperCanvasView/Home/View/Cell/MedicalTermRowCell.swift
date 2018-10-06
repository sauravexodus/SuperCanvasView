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
    var disposeBag = DisposeBag()
    let titleLabel = UILabel().then {
        $0.text = "Random text"
        $0.textColor = .black
    }
    
    let canvasView = CanvasView().then {
        $0.backgroundColor = .clear
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func prepareForReuse() {
        lastHeight = nil
        backgroundColor = .white
        canvasView.clear()
        canvasView.snp.removeConstraints()
        titleLabel.snp.removeConstraints()
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .white
        selectionStyle = .none
        
        canvasView.touchReachedBottom.map { [weak self] _ in
            guard let strongSelf = self, let lastHeight = strongSelf.lastHeight else { return }
            strongSelf.canvasView.snp.remakeConstraints { make in
                make.height.equalTo(lastHeight + 100)
                make.top.bottom.left.right.equalToSuperview().priority(.high)
            }
            strongSelf.lastHeight = lastHeight + 100
            strongSelf.setNeedsLayout()
            strongSelf.layoutIfNeeded()
        }.subscribe().disposed(by: disposeBag)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var lastHeight: Float?
    
    func configure(with text: String?, and lines: [Line], height: Float) {
        lastHeight = height
        titleLabel.text = text
        canvasView.lines = lines
        addSubview(titleLabel)
        addSubview(canvasView)
        if text == "Symptom" { backgroundColor = .blue }
        if text == "Diagnosis" { backgroundColor = .red }
        titleLabel.snp.remakeConstraints { make in
            make.height.equalTo(height)
            make.top.left.right.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
            make.bottom.equalToSuperview().priority(.low)
        }
        canvasView.snp.remakeConstraints { make in
            make.height.equalTo(height)
            make.top.bottom.left.right.equalToSuperview()
        }
    }
}
