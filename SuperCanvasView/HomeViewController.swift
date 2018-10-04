//
//  HomeViewController.swift
//  SuperCanvasView
//
//  Created by Sourav Chandra on 03/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import Then

struct SectionModel {
    let header: String
    let items: [String]
    var lines: [Line]
    
    static var dummy: [SectionModel] = {
        return Array(1...10).map {
            SectionModel(
                header: "Header \($0)",
                items: Array(1...10).map { "Item \($0)" },
                lines: []
            )
        }
    }()
}

final class HomeViewController: UIViewController {
    
    let tableView = UITableView().then {
        $0.rowHeight = PDFPageSize.A4.height
        $0.register(cellType: CanvasCell.self)
        $0.separatorStyle = .none
        $0.backgroundColor = .gray
        $0.panGestureRecognizer.allowedTouchTypes = [UITouchType.direct.rawValue as NSNumber]
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    let buttonsView = UIView().then {
        $0.backgroundColor = .black
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    let addTextButton = UIButton().then {
        $0.setTitle("Add Text", for: .normal)
    }
    
    var dataSource: [SectionModel] = SectionModel.dummy
    
    // MARK: Init methods
    
    init() {
        super.init(nibName: nil, bundle: nil)
        addSubviews()
        addConstraints()
        configureTableView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Instance methods
    
    private func addSubviews() {
        view.backgroundColor = .gray
        view.addSubview(buttonsView)
        buttonsView.addSubview(addTextButton)
        view.addSubview(tableView)
    }
    
    private func addConstraints() {
        buttonsView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(48)
            make.left.right.equalToSuperview()
        }
        addTextButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().inset(8)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(buttonsView.snp.bottom).offset(16)
            make.bottom.right.left.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16))
        }
    }
    
    private func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
    }
    
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: CanvasCell = tableView.dequeueReusableCell(for: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let cell: CanvasCell = tableView.dequeueReusableCell(for: indexPath)
        cell.configure(with: dataSource[indexPath.row])
        cell.canvasView.rx.lines.subscribe(onNext: { [weak self] lines in
            guard let strongSelf = self else { return }
            strongSelf.dataSource[indexPath.row].lines = lines
        })
        .disposed(by: cell.disposeBag)
    }
}
