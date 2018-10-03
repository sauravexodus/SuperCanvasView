//
//  CanvasCell.swift
//  SuperCanvasView
//
//  Created by Sourav Chandra on 03/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import UIKit
import Reusable

final class CanvasCell: UITableViewCell, Reusable {
    
    let separatorView = UIView().then {
        $0.backgroundColor = .gray
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = .white
        
        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { make in
            make.height.equalTo(16)
            make.bottom.left.right.equalToSuperview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
