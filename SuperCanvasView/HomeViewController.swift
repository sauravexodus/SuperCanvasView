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

extension Array {
    func grouped<S>(by keyForValue: (Element) throws -> S) rethrows -> [S: [Element]] {
        return try Dictionary(grouping: self, by: keyForValue)
    }
    
    var groupedBySequence: [Int: [Element]] {
        return enumerated().map { $0 }.grouped { $0.offset }.mapValues { $0.map { $0.element } }
    }
}

extension String {
    func height(constrainedTo width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedStringKey.font: font], context: nil)
        return boundingBox.height
    }
    
    func height(constrainedTo page: CGSize = PDFPageSize.A4, with font: UIFont) -> CGFloat {
        return height(constrainedTo: page.width, font: font)
    }
}

extension Array where Element == String {
    func height(constrainedTo width: CGFloat, font: UIFont) -> CGFloat {
        return map { $0.height(constrainedTo: width, font: font) }.reduce(0, { $0 + $1 })
    }
    
    func isExceedingA4Page(font: UIFont) -> Bool {
        return height(constrainedTo: PDFPageSize.A4.width, font: font) > PDFPageSize.A4.height
    }
}

extension Array where Element == SectionModel {
    
    func height(font: UIFont, headerSize: CGFloat = 64) -> CGFloat {
        return map { $0.items.height(constrainedTo: PDFPageSize.A4.width, font: font) }.reduce(headerSize, +)
    }
    
    func isExceedingA4Page(font: UIFont, headerSize: CGFloat = 64) -> Bool {
        return height(font: font, headerSize: headerSize) > PDFPageSize.A4.height
    }
    
    func remainingSpaceOnA4(font: UIFont, headerSize: CGFloat = 64) -> CGFloat {
        return PDFPageSize.A4.height - height(font: font, headerSize: headerSize)
    }
    
}

struct SectionModel {
    let header: String
    let items: [String]
    
    static var dummy: [SectionModel] = {
        return Array(0...500).map { "item \($0)" }
            .reduce([]) { (seed, acc) -> [[String]]  in
                var subArray = seed.last ?? []
                var seed = seed
                subArray.append(acc)
                if subArray.isExceedingA4Page(font: .systemFont(ofSize: 13)) {
                    subArray = [acc]
                    seed.append(subArray)
                } else if seed.isEmpty {
                    seed.append(subArray)
                } else {
                    seed[seed.count - 1] = subArray
                }
                return seed
            }
            .map { SectionModel.init(header: "", items: $0) }
    }()
    
    func split(accordingTo previousPage: PreviewPage) -> [SectionModel] {
        let remainingSpace = previousPage.sections.remainingSpaceOnA4(font: .systemFont(ofSize: 13))
        return []
    }
}

struct PreviewPage {
    let sections: [SectionModel]
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
        
        
        Array(1...20).map { SectionModel(header: "Header \($0)", items: Array(1...100).map { "Item \($0)" }) }
        
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
        cell.tableView.reloadData()
    }
}
