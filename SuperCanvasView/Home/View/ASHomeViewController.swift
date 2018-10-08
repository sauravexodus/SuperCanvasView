//
//  ASHomeViewController.swift
//  SuperCanvasView
//
//  Created by Sourav Chandra on 07/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import UIKit
import AsyncDisplayKit
import ReactorKit
import RxSwift
import RxCocoa
import RxGesture
import RxASDataSources
import RxViewController
import Then

extension CGSize {
    init(width: Float, height: Float) {
        self.init(width: CGFloat(width), height: CGFloat(height))
    }
}

extension UIView {
    var asNode: ASDisplayNode {
        return ASDisplayNode.init(viewBlock: { () -> UIView in
            return self
        }, didLoad: nil)
    }
}

extension Reactive where Base: ASDisplayNode {
    var tap: Observable<UITapGestureRecognizer> {
        return base.view.rx.tapGesture().when(.recognized)
    }
}

final class ASDisplayNodeWithBackgroundColor: ASDisplayNode {
    
    init(color: UIColor) {
        super.init()
        backgroundColor = color
    }
    
}

final class ContainerDisplayNode: ASDisplayNode {
    let addSymptomButtonNode = ASButtonNode().then {
        $0.setTitle("Add Symptom", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 120
    }
    
    let selectSymptomButtonNode = ASButtonNode().then {
        $0.setTitle("Select Symptom", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 120
    }
    
    let addDiagnosisButtonNode = ASButtonNode().then {
        $0.setTitle("Add Diagnosis", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 120
    }
    
    let selectDiagnosisButtonNode = ASButtonNode().then {
        $0.setTitle("Select Diagnosis", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 120
    }
    
    let deleteAllRowsButtonNode = ASButtonNode().then {
        $0.setTitle("Delete All", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 120
    }
    
    let printButtonNode = ASButtonNode().then {
        $0.setTitle("Print", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 120
    }
    
    let tableNode = ASTableNode(style: .plain).then {
        $0.view.panGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouchType.direct.rawValue)]
        $0.view.tableFooterView = UIView()
        $0.view.backgroundColor = .yellow
        $0.style.flexGrow = 1
    }
    
    override init() {
        super.init()
        backgroundColor = .black
        automaticallyManagesSubnodes = true
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let mainStack: ASStackLayoutSpec = .vertical()
        
        let spacer = ASLayoutSpec()
        spacer.style.flexGrow = 1
        
        let buttonsStack: ASStackLayoutSpec = .horizontal()
        buttonsStack.spacing = 8
        
        let backgroundColor = ASDisplayNodeWithBackgroundColor(color: .black)
        let backgroundSpec = ASBackgroundLayoutSpec(child: buttonsStack, background: backgroundColor)
        
        buttonsStack.style.preferredSize.height = 80
        buttonsStack.children = [
            addSymptomButtonNode,
            selectSymptomButtonNode,
            addDiagnosisButtonNode,
            selectDiagnosisButtonNode,
            deleteAllRowsButtonNode,
            printButtonNode,
            spacer
        ]
        
        mainStack.children = [backgroundSpec, tableNode]
        
        let insetSpec = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0), child: mainStack)
        return insetSpec
    }
}

final class ASHomeViewController: ASViewController<ContainerDisplayNode>, ReactorKit.View {
    var disposeBag: DisposeBag = DisposeBag()
    let dataSource: RxASTableReloadDataSource<ConsultationPageSection>
    let containerNode = ContainerDisplayNode()
    
    
    init(viewModel: HomeViewModel) {
        defer { self.reactor = viewModel }
        
        let configureCell: RxASTableReloadDataSource<ConsultationPageSection>.ConfigureCellBlock = { (ds, tableNode, index, item) in
            return { () -> ASCellNode in
                let cellNode = ASCellNode(viewBlock: { () -> UIView in
                    let view = ASMedicalTermCellNode()
                    view.backgroundColor = .white
                    view.configure(with: item.medicalTerm.name, and: [])
                    return view
                })
                cellNode.style.preferredSize = CGSize(width: Float.greatestFiniteMagnitude, height: item.height)
                return cellNode
            }
        }
        
        dataSource = RxASTableReloadDataSource(configureCellBlock: configureCell)

        super.init(node: containerNode)
        containerNode.frame = self.view.bounds
        containerNode.view.backgroundColor = .white
        containerNode.tableNode.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Bindings
    
    func bind(reactor: HomeViewModel) {
        bindActions(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindActions(reactor: HomeViewModel) {
        rx.viewDidAppear
            .mapTo(.initialLoad)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.selectSymptomButtonNode.rx.tap
            .mapTo(.select(.symptoms))
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.addSymptomButtonNode.rx.tap
            .map { _ in
                let heightsArray = [50, 100, 150]
                let randomHeightIndex = Int(arc4random_uniform(UInt32(heightsArray.count)))
                return .add(ConsultationRow(height: Float(heightsArray[randomHeightIndex]), medicalTerm: MedicalTerm(name: "Symptom", lines: [], medicalSection: .symptoms)))
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.selectDiagnosisButtonNode.rx.tap
            .mapTo(.select(.diagnoses))
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.addDiagnosisButtonNode.rx.tap
            .map { _ in
                let heightsArray = [50, 100, 150]
                let randomHeightIndex = Int(arc4random_uniform(UInt32(heightsArray.count)))
                return .add(ConsultationRow(height: Float(heightsArray[randomHeightIndex]), medicalTerm: MedicalTerm(name: "Diagnosis", lines: [], medicalSection: .diagnoses)))
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.deleteAllRowsButtonNode.rx
            .tap
            .mapTo(.deleteAll)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: HomeViewModel) {
        reactor.state.map { $0.pages }
            .bind(to: containerNode.tableNode.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.focusedIndexPath }
            .unwrap()
            .distinctUntilChanged { lhs, rhs in lhs.indexPath == rhs.indexPath }
            .subscribe(onNext: { [weak self] (result) in
                guard let strongSelf = self else { return }
                strongSelf.containerNode.tableNode.scrollToRow(at: result.indexPath, at: result.scrollPosition, animated: true)
            })
            .disposed(by: disposeBag)
    }
}

extension ASHomeViewController: ASTableDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .gray
        return view
    }
}