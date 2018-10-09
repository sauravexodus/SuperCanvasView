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
import ReactorKit
import RxDataSources
import RxViewController

final class HomeViewController: UIViewController, View {
    var disposeBag = DisposeBag()
    
    // MARK: UI Elements
    
    let tableView = UITableView().then {
        $0.rowHeight = UITableViewAutomaticDimension
        $0.estimatedRowHeight = 100.0
        $0.register(cellType: MedicalTermRowCell.self)
        $0.separatorStyle = .none
        $0.backgroundColor = .gray
        $0.panGestureRecognizer.allowedTouchTypes = [UITouchType.direct.rawValue as NSNumber]
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    let buttonsView = UIView().then {
        $0.backgroundColor = .black
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    let addMedicalTermRow = UIButton().then {
        $0.setTitle("Add", for: .normal)
    }
    
    let deleteAllRows = UIButton().then {
        $0.setTitle("Delete All", for: .normal)
    }
    
    let printButton = UIButton().then {
        $0.setTitle("Print", for: .normal)
    }
    
    // MARK: Data Source

    var consultationRowsDataSource: RxTableViewSectionedReloadDataSource<ConsultationPageSection> = HomeViewController.dataSource()
    
    // MARK: Init methods
    
    init(reactor: HomeViewModel) {
        defer { self.reactor = reactor }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        setup()
    }
    
    // MARK: Instance methods
    
    private func setup() {
        addSubviews()
        addConstraints()
        tableView.sectionFooterHeight = 100
        tableView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)
    }
    
    private func addSubviews() {
        view.backgroundColor = .gray
        view.addSubview(buttonsView)
        buttonsView.addSubview(addMedicalTermRow)
        buttonsView.addSubview(deleteAllRows)
        buttonsView.addSubview(printButton)
        view.addSubview(tableView)
        tableView.backgroundColor = .yellow
    }
    
    private func addConstraints() {
        buttonsView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(48)
            make.left.right.equalToSuperview()
        }
        addMedicalTermRow.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().inset(8)
        }
        deleteAllRows.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalTo(addMedicalTermRow.snp.right).offset(32)
            make.bottom.equalToSuperview().inset(8)
        }
        printButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalTo(deleteAllRows.snp.right).offset(32)
            make.bottom.equalToSuperview().inset(8)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(buttonsView.snp.bottom).offset(16)
            make.bottom.right.left.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16))
        }
    }
    
    func bind(reactor: HomeViewModel) {
        bindActions(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindActions(reactor: HomeViewModel) {
        rx.viewDidAppear
            .mapTo(.initialLoad)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        addMedicalTermRow.rx.tap
            .map { _ in
                let heightsArray = [50, 100, 150]
                let randomHeightIndex = Int(arc4random_uniform(UInt32(heightsArray.count)))
                let medicalSectionsArray = [MedicalSection.symptoms(name: "Symptom", lines: []), MedicalSection.diagnoses(name: "Diagnosis", lines: [])]
                let randomSectionIndex = Int(arc4random_uniform(UInt32(medicalSectionsArray.count)))
                return .add(ConsultationRow(height: Float(heightsArray[randomHeightIndex]), medicalSection: medicalSectionsArray[randomSectionIndex]))
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        deleteAllRows.rx.tap
            .mapTo(.deleteAll)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: HomeViewModel) {
        reactor.state.map { $0.pages }
            .bind(to: tableView.rx.items(dataSource: consultationRowsDataSource))
            .disposed(by: disposeBag)
    }
}

extension HomeViewController {
    static func dataSource() -> RxTableViewSectionedReloadDataSource<ConsultationPageSection> {
        return RxTableViewSectionedReloadDataSource<ConsultationPageSection>(
            configureCell: { dataSource, tableView, indexPath, consultationRow -> UITableViewCell in
                let cell: MedicalTermRowCell = tableView.dequeueReusableCell(for: indexPath)
                switch consultationRow.medicalSection {
                case let .symptoms(name, lines):
                    cell.configure(with: name, and: lines, height: consultationRow.height)
                case let .diagnoses(name, lines):
                    cell.configure(with: name, and: lines, height: consultationRow.height)
                default: cell.configure(with: nil, and: [], height: consultationRow.height)
                }
                return cell
        }
    )}
}

extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 25.0
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        view.tintColor = .gray
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