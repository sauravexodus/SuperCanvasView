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
import RxSwift

final class SimpleCell: UITableViewCell, Reusable {

    let titleLabel = UILabel().then {
        $0.text = "Random text"
        $0.textColor = .black
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with text: String) {
        titleLabel.text = text
    }

}

final class CanvasCell: UITableViewCell, Reusable {
    
    let separatorView = UIView().then {
        $0.backgroundColor = .gray
    }
    
    let tableView = UITableView().then {
        $0.rowHeight = UITableViewAutomaticDimension
        $0.estimatedRowHeight = 48
        $0.separatorInset = .zero
        $0.tableFooterView = UIView()
        $0.register(cellType: SimpleCell.self)
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    let canvasView = CanvasView().then {
        $0.backgroundColor = .blue
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    var items: PublishSubject<[String]> = .init()
    
    var disposeBag = DisposeBag()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = .white
        
        contentView.addSubview(separatorView)
        contentView.addSubview(tableView)
        contentView.addSubview(canvasView)
        
        tableView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
        
        canvasView.snp.makeConstraints { make in
            make.edges.equalTo(tableView)
        }
        
        separatorView.snp.makeConstraints { make in
            make.top.equalTo(tableView.snp.bottom)
            make.height.equalTo(16)
            make.bottom.left.right.equalToSuperview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = .init()
    }
    
//    func configure(with sectionModel: SectionModel) {
//        items.bind(to: tableView.rx.items(cellIdentifier: "SimpleCell", cellType: SimpleCell.self)) { row, element, cell in
//            cell.configure(with: element)
//        }.disposed(by: disposeBag)
//        items.onNext(sectionModel.items)
//        canvasView.lines = sectionModel.lines
//        canvasView.setNeedsDisplay()
//    }
    
}
