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

final class ASAwareTableNode: ASTableNode, ASTableDelegate, UIScrollViewDelegate {
    enum InteractionType: String {
        case scribble
        case tap
        case scroll
        case initial
    }
    
    let endUpdateSubject = PublishSubject<(indexPath: IndexPath?, interactionType: InteractionType)>()
    let endContractSubject = PublishSubject<HomeViewModel.IndexPathWithHeight?>()
    let disposeBag = DisposeBag()
    
    override init(style: UITableViewStyle) {
        super.init(style: style)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        endUpdateSubject.onNext((indexPath: nil, interactionType: .scroll))
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
    
    let tableNode = ASAwareTableNode(style: .plain).then {
        $0.view.panGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouchType.direct.rawValue)]
        $0.view.tableFooterView = UIView()
        $0.view.backgroundColor = .white
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
            spacer
        ]
        
        mainStack.children = [backgroundSpec, tableNode]
        
        let insetSpec = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0), child: mainStack)
        return insetSpec
    }
}

final class ASHomeViewController: ASViewController<ContainerDisplayNode>, ReactorKit.View {
    var disposeBag: DisposeBag = DisposeBag()
    let dataSource: RxASTableAnimatedDataSource<ConsultationPageSection>
    let containerNode = ContainerDisplayNode()
    
    init(viewModel: HomeViewModel) {
        defer { self.reactor = viewModel }
        
        let configureCell: RxASTableAnimatedDataSource<ConsultationPageSection>.ConfigureCellBlock = { (ds, tableNode, index, item) in
            return {
                switch item.medicalTerm.sectionOfSelf {
                case .diagnoses:
                    let node = ASMedicalTermCellNode<EmptyCellNode<Diagnosis>>()
                    node.configure(with: item)
                    return node
                case .symptoms:
                    let node = ASMedicalTermCellNode<EmptyCellNode<Symptom>>()
                    node.configure(with: item)
                    return node
                default:
                    let node = ASMedicalTermCellNode<EmptyCellNode<NoMedicalTerm>>()
                    node.configure(with: item)
                    return node
                }
            }
        }
        
        dataSource = RxASTableAnimatedDataSource(configureCellBlock: configureCell)

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

        containerNode.tableNode.endContractSubject
            .pausableBufferedCombined(
                containerNode.tableNode.endContractSubject
                    .debounce(3, scheduler: MainScheduler.instance)
                    .flatMap { _ in Observable.concat(.just(true), .just(false)) }
                    .startWith(false),
                limit: 100)
            .map { .updateHeights($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        containerNode.printButtonNode.rx
            .tap
            .flatMap { [weak self] _ -> Observable<[UIImage]> in
                guard let strongSelf = self  else { return .empty() }
                return strongSelf.generatePages()
            }
            .map { .print($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: HomeViewModel) {
        reactor.state.map { $0.pages }
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
    
    private func generatePages() -> Observable<[UIImage]> {
        return Observable<Int>.interval(0.2, scheduler: MainScheduler.instance)
            .take(containerNode.tableNode.numberOfSections)
            .concatMap { [weak self] section -> Observable<UIImage?> in
                guard let strongSelf = self else { return .just(nil) }
                return strongSelf.captureSinglePage(section)
            }
            .unwrap()
            .reduce([], accumulator: { images, page in
                var `images` = images
                images.append(page)
                return images
            })
            .do(onDispose: { [weak self] in
                self?.containerNode.tableNode.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            })
    }
    
    private func captureSinglePage(_ section: Int) -> Observable<UIImage?> {
        return Observable.from(Array(0...containerNode.tableNode.numberOfRows(inSection: section) - 1))
            .concatMap { [weak self] row -> Observable<UIImage?> in
                guard let strongSelf = self else { return .just(nil) }
                let indexPath = IndexPath(row: row, section: section)
                strongSelf.containerNode.tableNode.scrollToRow(at: indexPath, at: .top, animated: true)
                let cell = strongSelf.containerNode.tableNode.cellForRow(at: indexPath)
                return cell?.contentView.rx.swCapture() ?? .just(nil)
            }
            .unwrap()
            .reduce([], accumulator: { images, image in
                var `images` = images
                images.append(image)
                return images
            })
            .map { $0.mergeToSingleImage() }
    }
}

extension ASHomeViewController: ASTableDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }
    
    func tableNode(_ tableNode: ASTableNode, willDisplayRowWith node: ASCellNode) {
        guard let `reactor` = reactor else { return }
        if let medicalTermCellNode = node as? ASMedicalTermCellNode<EmptyCellNode<Diagnosis>> {
            medicalTermCellNode.linesChanged.debounce(0.3, scheduler: MainScheduler.instance)
                .map { .updateLines(indexPath: $0.indexPath, lines: $0.lines) }
                .bind(to: reactor.action)
                .disposed(by: medicalTermCellNode.disposeBag)
        } else if let medicalTermCellNode = node as? ASMedicalTermCellNode<EmptyCellNode<Symptom>> {
            medicalTermCellNode.linesChanged.debounce(0.3, scheduler: MainScheduler.instance)
                .map { .updateLines(indexPath: $0.indexPath, lines: $0.lines) }
                .bind(to: reactor.action)
                .disposed(by: medicalTermCellNode.disposeBag)
        } else if let medicalTermCellNode = node as? ASMedicalTermCellNode<EmptyCellNode<NoMedicalTerm>> {
            medicalTermCellNode.linesChanged.debounce(0.3, scheduler: MainScheduler.instance)
                .map { .updateLines(indexPath: $0.indexPath, lines: $0.lines) }
                .bind(to: reactor.action)
                .disposed(by: medicalTermCellNode.disposeBag)
        }
    }
    
    /// Since ASAwareTableNode's delegate is HomeViewController. We have to do this so that ASAwareTableNode is aware of the scrolling.
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        containerNode.tableNode.scrollViewDidScroll(scrollView)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .gray
        return view
    }
}
