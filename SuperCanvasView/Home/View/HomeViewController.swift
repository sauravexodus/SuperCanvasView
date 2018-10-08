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
    
    let addDrawingRow = UIButton().then {
        $0.setTitle("Add Drawing Row", for: .normal)
    }
    
    let addMedicalTermRow = UIButton().then {
        $0.setTitle("Add Medical Term Row", for: .normal)
    }
    
    let addTenRows = UIButton().then {
        $0.setTitle("Add Ten Rows", for: .normal)
    }
    
    let deleteAllRows = UIButton().then {
        $0.setTitle("Delete All Rows", for: .normal)
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
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 2
        tableView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)
    }
    
    private func addSubviews() {
        view.backgroundColor = .gray
        view.addSubview(buttonsView)
        buttonsView.addSubview(addMedicalTermRow)
        buttonsView.addSubview(addTenRows)
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
            make.left.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().inset(8)
        }
        addTenRows.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalTo(addMedicalTermRow.snp.right).offset(8)
            make.bottom.equalToSuperview().inset(8)
        }
        deleteAllRows.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalTo(addTenRows.snp.right).offset(8)
            make.bottom.equalToSuperview().inset(8)
        }
        printButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalTo(deleteAllRows.snp.right).offset(8)
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
                return .add(ConsultationRow(height: Float([50, 100, 150].randomElement() ?? 0), medicalSection: [MedicalSection.symptoms(name: "Symptom", lines: []), MedicalSection.diagnoses(name: "Diagnosis", lines: [])].randomElement() ?? MedicalSection.symptoms(name: "Shouldn't show up", lines: [])))
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        addTenRows.rx.tap
            .mapTo(.addTen)
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
                cell.rx.didBeginUpdate.map {
                    tableView.beginUpdates()
                }.subscribe().disposed(by: cell.disposeBag)
                
                cell.rx.didEndUpdate.map {
                    tableView.endUpdates()
                }.subscribe().disposed(by: cell.disposeBag)

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
        return 100.0
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        view.tintColor = .green
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
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
