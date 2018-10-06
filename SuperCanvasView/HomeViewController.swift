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
import RxSwift
import WebKit

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
    
    let printButton = UIButton().then {
        $0.setTitle("Print", for: .normal)
    }
    
    let disposeBag = DisposeBag()
    
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
    
    override func viewDidLoad() {
        printButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.showPrint()
            })
            .disposed(by: disposeBag)
    }
    
    private func showPrint() {
        var images: [UIImage] = []
        for section in 0...tableView.numberOfSections - 1 {
            for row in 0...tableView.numberOfRows(inSection: section) - 1 {
                let indexPath = IndexPath(row: row, section: section)
                tableView.scrollToRow(at: indexPath, at: .top, animated: false)
//                tableView.reloadData()
//                tableView.setNeedsLayout()
                tableView.layoutIfNeeded()
                let cell = tableView.cellForRow(at: indexPath)
                cell?.swCapture { image in
                    guard let `image` = image else { return }
                    images.append(image)
                }
            }
        }
        printConsultation(images: images)
    }
    
    private func printConsultation(images: [UIImage]) {
        let pi = UIPrintInfo(dictionary: nil)
        pi.outputType = .general
        pi.jobName = "JOB"
        pi.orientation = .portrait
        pi.duplex = .longEdge
        let pic = UIPrintInteractionController.shared
        pic.printInfo = pi
        pic.printingItems = images
        pic.present(animated: true)
    }
    
    // MARK: Instance methods
    
    private func addSubviews() {
        view.backgroundColor = .gray
        view.addSubview(buttonsView)
        buttonsView.addSubview(addTextButton)
        buttonsView.addSubview(printButton)
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
        printButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalTo(addTextButton.snp.right).offset(8)
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
        return cellgit@github.com:sauravexodus/SuperCanvasView.git
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

extension UIImage {
    func imageWithInsets(insetDimen: CGFloat) -> UIImage {
        return imageWithInset(insets: UIEdgeInsets(top: insetDimen, left: insetDimen, bottom: insetDimen, right: insetDimen))
    }
    
    func imageWithInset(insets: UIEdgeInsets) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(
            CGSize(width: self.size.width + insets.left + insets.right,
                   height: self.size.height + insets.top + insets.bottom), false, self.scale)
        let origin = CGPoint(x: insets.left, y: insets.top)
        self.draw(at: origin)
        let imageWithInsets = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageWithInsets!
    }
    
}
