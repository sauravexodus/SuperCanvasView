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

final class ASDisplayNodeWithBackgroundColor: ASDisplayNode {
    init(color: UIColor) {
        super.init()
        backgroundColor = color
    }
}

final class ContainerDisplayNode: ASDisplayNode {
    let addSymptomButtonNode = ASButtonNode().then {
        $0.setTitle("Add Symptom", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 100
    }
    
    let selectSymptomButtonNode = ASButtonNode().then {
        $0.setTitle("Select Symptom", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 100
    }
    
    let addDiagnosisButtonNode = ASButtonNode().then {
        $0.setTitle("Add Diagnosis", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 100
    }
    
    let selectDiagnosisButtonNode = ASButtonNode().then {
        $0.setTitle("Select Diagnosis", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 100
    }
    
    let deleteAllRowsButtonNode = ASButtonNode().then {
        $0.setTitle("Delete All", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 100
    }
    
    let printButtonNode = ASButtonNode().then {
        $0.setTitle("Print", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 100
    }
    
    let showPageBreaksButtonNode = ASButtonNode().then {
        $0.setTitle("Page Breaks", with: .systemFont(ofSize: 13), with: .white, for: .normal)
        $0.style.preferredSize.width = 100
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
        $0.view.tableFooterView?.frame.size.height = PageSize.A4.height
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
            deleteAllRowsButtonNode,
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
            .mapTo(.select(.symptoms))
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.addSymptomButtonNode.rx
            .tap
            .map { _ in
                return .add(Symptom(name: "Symptom"))
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.selectDiagnosisButtonNode.rx
            .tap
            .mapTo(.select(.diagnoses))
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.addDiagnosisButtonNode.rx
            .tap
            .map { _ in
                return .add(Diagnosis(name: "Diagnosis"))
            }
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
                guard let strongSelf = self  else { return .empty() }
                return strongSelf.containerNode.tableNode.generatePages(PageSize.A4.height)
            }
            .map { .print($0) }
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
            .unwrap()
            .distinctUntilChanged { lhs, rhs in lhs.indexPath == rhs.indexPath }
            .subscribe(onNext: { [weak self] (result) in
                guard let strongSelf = self else { return }
                strongSelf.containerNode.tableNode.scrollToRow(at: result.indexPath, at: result.scrollPosition, animated: true)
            })
            .disposed(by: disposeBag)
    }
}
