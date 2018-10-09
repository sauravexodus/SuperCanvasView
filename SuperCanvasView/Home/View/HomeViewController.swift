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

final class ConsultationTableView: UITableView {
    var disposeBag = DisposeBag()
    
    var cellsQueuedForContraction: [IndexPath] = []
    var cellUnderEdit: IndexPath?
    
    func resetContractQueue() {
        cellsQueuedForContraction = []
    }
    
    func contract(_ indexPath: IndexPath) {
        cellsQueuedForContraction.append(indexPath)
        if indexPath == cellUnderEdit {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [], animations: {
                self.beginUpdates()
                for path in self.cellsQueuedForContraction {
                    let cell = self.cellForRow(at: path) as? MedicalTermRowCell
                    cell?.contract()
                }
                self.endUpdates()
                self.resetContractQueue()
            }, completion: nil)
        }
    }

    public override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
    }
    
    override func reloadData() {
        resetContractQueue()
        super.reloadData()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero, style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class HomeViewController: UIViewController, View {
    var disposeBag = DisposeBag()
    
    // MARK: UI Elements
    
    let tableView = ConsultationTableView().then {
        $0.rowHeight = UITableViewAutomaticDimension
        $0.estimatedRowHeight = 100.0
        $0.register(cellType: MedicalTermRowCell.self)
        $0.separatorStyle = .singleLine
        $0.backgroundColor = .gray
        $0.panGestureRecognizer.allowedTouchTypes = [UITouchType.direct.rawValue as NSNumber]
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    let buttonsView = UIView().then {
        $0.backgroundColor = .black
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    let addSymptomRow = UIButton().then {
        $0.setTitle("Add Symptom", for: .normal)
    }
    
    let addDiagnosisRow = UIButton().then {
        $0.setTitle("Add Diagnosis", for: .normal)
    }
    
    let selectSymptomRow = UIButton().then {
        $0.setTitle("Select Symptom", for: .normal)
    }
    
    let selectDiagnosisRow = UIButton().then {
        $0.setTitle("Select Diagnosis", for: .normal)
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
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 2
        tableView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)
    }
    
    private func addSubviews() {
        view.backgroundColor = .gray
        view.addSubview(buttonsView)
        buttonsView.addSubview(selectSymptomRow)
        buttonsView.addSubview(addSymptomRow)
        buttonsView.addSubview(selectDiagnosisRow)
        buttonsView.addSubview(addDiagnosisRow)
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
        selectSymptomRow.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().inset(8)
        }
        addSymptomRow.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalTo(selectSymptomRow.snp.right).offset(16)
            make.bottom.equalToSuperview().inset(8)
        }
        selectDiagnosisRow.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalTo(addSymptomRow.snp.right).offset(16)
            make.bottom.equalToSuperview().inset(8)
        }
        addDiagnosisRow.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalTo(selectDiagnosisRow.snp.right).offset(16)
            make.bottom.equalToSuperview().inset(8)
        }
        deleteAllRows.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalTo(addDiagnosisRow.snp.right).offset(16)
            make.bottom.equalToSuperview().inset(8)
        }
        printButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalTo(deleteAllRows.snp.right).offset(16)
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
        
        selectSymptomRow.rx.tap
            .mapTo(.select(.symptoms))
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        addSymptomRow.rx.tap
            .map { _ in
                let heightsArray = [50, 100, 150]
                let randomHeightIndex = Int(arc4random_uniform(UInt32(heightsArray.count)))
                return .add(ConsultationRow(height: Float(heightsArray[randomHeightIndex]), medicalTerm: MedicalTerm(name: "Symptom", lines: [], medicalSection: .symptoms)))
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        selectDiagnosisRow.rx.tap
            .mapTo(.select(.diagnoses))
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        addDiagnosisRow.rx.tap
            .map { _ in
                let heightsArray = [50, 100, 150]
                let randomHeightIndex = Int(arc4random_uniform(UInt32(heightsArray.count)))
                return .add(ConsultationRow(height: Float(heightsArray[randomHeightIndex]), medicalTerm: MedicalTerm(name: "Diagnosis", lines: [], medicalSection: .diagnoses)))
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
        
        reactor.state.map { $0.focusedIndexPath }
            .unwrap()
            .distinctUntilChanged { lhs, rhs in lhs.indexPath == rhs.indexPath }
            .subscribe(onNext: { [weak self] result in
                guard let strongSelf = self else { return }
                strongSelf.tableView.scrollToRow(at: result.indexPath, at: result.scrollPosition, animated: true)
            })
            .disposed(by: disposeBag)
    }
}

extension HomeViewController {
    static func dataSource() -> RxTableViewSectionedReloadDataSource<ConsultationPageSection> {
        return RxTableViewSectionedReloadDataSource<ConsultationPageSection>(
            configureCell: { dataSource, tableView, indexPath, consultationRow -> UITableViewCell in
                let tableView = tableView as! ConsultationTableView
                let cell: MedicalTermRowCell = tableView.dequeueReusableCell(for: indexPath)

                cell.rx.didBeginUpdate.map {
                    tableView.beginUpdates()
                }.subscribe().disposed(by: cell.disposeBag)
                
                cell.rx.didEndUpdate.map {
                    tableView.endUpdates()
                }.subscribe().disposed(by: cell.disposeBag)

                cell.rx.didBeginWriting
                    .map { tableView.cellUnderEdit = indexPath }
                    .subscribe()
                    .disposed(by: cell.disposeBag)
                
                cell.rx.wantsContract
                    .map { tableView.contract(indexPath) }
                    .subscribe()
                    .disposed(by: cell.disposeBag)

                let name = consultationRow.medicalTerm.name
                let lines = consultationRow.medicalTerm.lines
                let isPadder = consultationRow.medicalTerm.isPadder
                
                switch consultationRow.medicalTerm.medicalSection {
                case .symptoms:
                    cell.backgroundColor = isPadder ? .white : .blue
                    cell.configure(with: name, and: lines, height: consultationRow.height)
                    return cell
                case .diagnoses:
                    cell.backgroundColor = isPadder ? .white : .red
                    cell.configure(with: name, and: lines, height: consultationRow.height)
                    return cell
                }
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
