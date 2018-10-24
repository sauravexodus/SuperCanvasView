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
import DeepDiff
//import DHSmartScreenshot

final class ASDisplayNodeWithBackgroundColor: ASDisplayNode {
    init(color: UIColor) {
        super.init()
        backgroundColor = color
    }
}

final class ContainerDisplayNode: ASDisplayNode {
    let addSymptomButtonNode = ASButtonNode().then {
        $0.setTitle("AS", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 40
    }
    
    let selectSymptomButtonNode = ASButtonNode().then {
        $0.setTitle("SS", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 40
    }
    
    let addDiagnosisButtonNode = ASButtonNode().then {
        $0.setTitle("AD", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 40
    }
    
    let selectDiagnosisButtonNode = ASButtonNode().then {
        $0.setTitle("SD", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 40
    }
    
    let selectObstetricHistoryButton = ASButtonNode().then {
        $0.setTitle("SOH", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 40
    }
    
    let selectMenstrualHistoryButton = ASButtonNode().then {
        $0.setTitle("SMH", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 40
    }
    
    let deleteAllRowsButtonNode = ASButtonNode().then {
        $0.setTitle("DA", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 40
    }
    
    let printButtonNode = ASButtonNode().then {
        $0.setTitle("P", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 40
    }

    let contractButtonNode = ASButtonNode().then {
        $0.setTitle("Contract", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 100
    }
    
    let showPageBreaksButtonNode = ASButtonNode().then {
        $0.setTitle("PB", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 40
    }
    
    let undoButtonNode = ASButtonNode().then {
        $0.setTitle("Undo", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 100
    }
    
    let redoButtonNode = ASButtonNode().then {
        $0.setTitle("Redo", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 100
    }
    
    let clearButtonNode = ASButtonNode().then {
        $0.setTitle("Clear", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 100
    }
    
    let pencilButtonNode = ASButtonNode().then {
        $0.setTitle("Pencil", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 100
    }
    
    let eraserButtonNode = ASButtonNode().then {
        $0.setTitle("Eraser", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 100
    }
    
    let tableNode = ASAwareTableNode(style: .plain).then {
        $0.view.panGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouchType.direct.rawValue)]
        $0.view.tableFooterView = UIView()
        $0.view.backgroundColor = .white
        $0.view.tableFooterView = UIView()
        $0.view.tableFooterView?.frame.size.height = PageSize.selectedPage.heightRemovingMargins
        $0.style.flexGrow = 1
    }
    
    let idleSubject = PublishSubject<Void>()
    
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
            selectMenstrualHistoryButton,
            selectObstetricHistoryButton,
            deleteAllRowsButtonNode,
            contractButtonNode,
            printButtonNode,
            showPageBreaksButtonNode,
            spacer
        ]
        
        let canvasControlsStack: ASStackLayoutSpec = .horizontal()
        canvasControlsStack.style.preferredSize.height = 48
        canvasControlsStack.children = [
            pencilButtonNode,
            eraserButtonNode,
            undoButtonNode,
            redoButtonNode,
            clearButtonNode
        ]
        canvasControlsStack.spacing = 8
        
        let canvasControlsBackground = ASBackgroundLayoutSpec(child: canvasControlsStack, background: ASDisplayNodeWithBackgroundColor(color: .purple))
        
        mainStack.children = [backgroundSpec, canvasControlsBackground, tableNode]
        
        let insetSpec = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0), child: mainStack)
        return insetSpec
    }
}

final class ASHomeViewController: ASViewController<ContainerDisplayNode>, ReactorKit.View {
    var disposeBag: DisposeBag = DisposeBag()
    let containerNode = ContainerDisplayNode()
    
    init(viewModel: HomeViewModel) {
        defer { self.reactor = viewModel }
        
        super.init(node: containerNode)
        containerNode.frame = self.view.bounds
        containerNode.view.backgroundColor = .white
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
        
        containerNode.selectSymptomButtonNode.rx
            .tap
            .mapTo(.select(MedicalSection(.symptoms)))
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.addSymptomButtonNode.rx
            .tap
            .map { _ in
                return .add(Symptom(name: "Symptom"), MedicalTermSection.symptoms)
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.selectDiagnosisButtonNode.rx
            .tap
            .mapTo(.select(MedicalSection(.diagnoses)))
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.addDiagnosisButtonNode.rx
            .tap
            .map { _ in
                return .add(Diagnosis(name: "Diagnosis"), MedicalTermSection.diagnoses)
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.selectMenstrualHistoryButton.rx
            .tap
            .mapTo(.select(MedicalSection(.menstrualHistory)))
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.selectObstetricHistoryButton.rx
            .tap
            .mapTo(.select(MedicalSection(.obstetricHistory)))
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.deleteAllRowsButtonNode.rx
            .tap
            .mapTo(.deleteAll)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.tableNode.rx
            .linesUpdated
            .map { .updateLines(indexPath: $0.indexPath, lines: $0.lines) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.printButtonNode.rx
            .tap
            .flatMap { [weak self] _ -> Observable<[UIImage]> in
                guard let strongSelf = self else { return .empty() }
                return strongSelf.containerNode.tableNode.generatePages()
            }
            .map { .print($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.contractButtonNode.rx
            .tap
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let strongSelf = self else { return .empty() }
                return strongSelf.containerNode.tableNode.contract()
            }
            .mapTo(.removePageBreaks)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.showPageBreaksButtonNode.rx
            .tap
            .mapTo(.showPageBreaks)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        containerNode.tableNode
            .itemDeleted
            .map { .delete($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.tableNode.rx.didScroll
            .mapTo(.scroll)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.pencilButtonNode.rx.tap.mapTo(.pencil).bind(to: containerNode.tableNode.rx.canvasTool).disposed(by: disposeBag)
        containerNode.eraserButtonNode.rx.tap.mapTo(.eraser).bind(to: containerNode.tableNode.rx.canvasTool).disposed(by: disposeBag)
        containerNode.undoButtonNode.rx.tap.mapTo(()).bind(to: containerNode.tableNode.rx.undo).disposed(by: disposeBag)
        containerNode.redoButtonNode.rx.tap.mapTo(()).bind(to: containerNode.tableNode.rx.redo).disposed(by: disposeBag)
        containerNode.clearButtonNode.rx.tap.mapTo(()).bind(to: containerNode.tableNode.rx.clear).disposed(by: disposeBag)
        
    }
    
    private func bindState(reactor: HomeViewModel) {
        reactor.state.map { $0.sections }
            .distinctUntilChanged { old, new in
                let oldHashes = old.map { $0.items.map { $0.id } }.reduce([], { item, acc -> [String] in
                    var mutable = item
                    mutable.append(contentsOf: acc)
                    return mutable
                })
                let newHashes = new.map { $0.items.map { $0.id } }.reduce([], { item, acc -> [String] in
                    var mutable = item
                    mutable.append(contentsOf: acc)
                    return mutable
                })
                return diff(old: oldHashes, new: newHashes).isEmpty
            }
            .bind(to: containerNode.tableNode.rx.items(dataSource: containerNode.tableNode.animatedDataSource))
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.focusedIndexPath }
            .distinctUntilChanged { lhs, rhs in lhs?.indexPath == rhs?.indexPath }
            .unwrap()
            .subscribe(onNext: { [weak self] (result) in
                guard let strongSelf = self else { return }
                strongSelf.containerNode.tableNode.scrollToRow(at: result.indexPath, at: result.scrollPosition, animated: true)
            })
            .disposed(by: disposeBag)
    }
}
