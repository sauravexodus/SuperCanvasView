//
//  ASMedicalTermNodeCell.swift
//  SuperCanvasView
//
//  Created by Sourav Chandra on 07/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import SnapKit
import RxSwift

final class ASMedicalTermCellNode<ContentNode: CellContentNode>: ASCellNode where ContentNode.RepresentationTarget: MedicalTermType {
    let titleTextNode = ASTextNode().then {
        $0.maximumNumberOfLines = 0
    }
    
    let contentNode = ContentNode().then { _ in
        
    }
    
    let canvasNode = ASDisplayNode {
        CanvasView().then { $0.backgroundColor = .clear }
    }

    let headerTextNode = ASTextNode().then {
        $0.maximumNumberOfLines = 0
    }
    
    let editButtonNode = ASButtonNode().then {
        $0.setTitle("EDIT", with: UIFont.systemFont(ofSize: 12, weight: .semibold), with: .black, for: .normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }
    
    let deleteButtonNode = ASButtonNode().then {
        $0.setTitle("DELETE", with: UIFont.systemFont(ofSize: 12, weight: .semibold), with: .black, for: .normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }

    var header: String?
    let maximumHeight: CGFloat = 300
    let disposeBag = DisposeBag()
    var item: ConsultationRow?
    
    // MARK: Init methods
    
    override init() {
        super.init()
        selectionStyle = .none
        backgroundColor = .white
        automaticallyManagesSubnodes = true
    }
    
    // MARK: Instance methods
    
    override func didLoad() {
        setupStyles()
        setupBindings()
        setupCanvasExpanding()
        setupCanvas()
    }
    
    private func setupCanvas() {
        guard let `item` = item, let canvasView = canvasNode.view as? CanvasView else { return }
        canvasView.lines = item.lines
        canvasView.setNeedsDisplay()
        
        canvasView.rx.lines.subscribe(onNext: { [weak self] lines in
            guard let strongSelf = self else { return }
            strongSelf.item?.lines = lines
        })
        .disposed(by: disposeBag)
    }
    
    private func setupCanvasExpanding() {
        guard let canvasView = canvasNode.view as? CanvasView,
            let tableNode = owningNode as? ASAwareTableNode else { return }
        
        let tapObservable = rx.tapGesture { gesture, _ in
            gesture.allowedTouchTypes = [NSNumber(value: UITouchType.direct.rawValue)]
            }
            .mapTo(())
        
        Observable.merge(
            tapObservable,
            canvasView.rx.pencilTouchDidNearBottom
            )
            .subscribe(onNext: { [unowned self] _ in
                UIView.setAnimationsEnabled(false)
                self.expand()
            })
            .disposed(by: disposeBag)
        
        Observable.merge(tapObservable.mapTo((indexPath: indexPath, interactionType: .tap)),
                         canvasView.rx.pencilDidStopMoving.mapTo((indexPath: indexPath, interactionType: .scribble)))
            .bind(to: tableNode.endUpdateSubject)
            .disposed(by: disposeBag)

        tableNode.endUpdateSubject
            .pausableBufferedCombined(
                tableNode.endUpdateSubject
                    .debounce(1.5, scheduler: MainScheduler.instance)
                    .flatMap { _ in Observable.concat(.just(true), .just(false)) }
                    .startWith(false),
                limit: nil)
            .debug("reached here")
            .subscribe(onNext: { [unowned self] type in
                UIView.setAnimationsEnabled(true)
                self.contract(type: type)
            })
            .disposed(by: disposeBag)
    }
    
    private func setupBindings() {
        editButtonNode.rx.tap
            .subscribe(onNext: { _ in
                print("Edit Tapped")
            })
            .disposed(by: disposeBag)
        
        deleteButtonNode.rx.tap
            .subscribe(onNext: { _ in
                print("Delete Tapped")
            })
            .disposed(by: disposeBag)
    }
    
    private func setupStyles() {
        editButtonNode.layer.borderColor = UIColor.black.cgColor
        editButtonNode.layer.borderWidth = 2
        editButtonNode.layer.cornerRadius = 3
        
        deleteButtonNode.layer.borderColor = UIColor.black.cgColor
        deleteButtonNode.layer.borderWidth = 2
        deleteButtonNode.layer.cornerRadius = 3
    }

    func configure(with item: ConsultationRow) {
        guard let term = item.medicalTerm as? ContentNode.RepresentationTarget else {
            print("Something has gone horribly, horribly awry...")
            return
        }
        if let header = item.header, item.needsHeader {
            headerTextNode.attributedText = .init(string: header, attributes: [.foregroundColor: UIColor.white])
        }
        style.preferredSize.height = min(CGFloat(max(CGFloat(item.heightWithHeader), item.lines.highestY ?? 0)), maximumHeight)
        titleTextNode.attributedText = .init(string: term.name ?? "", attributes: [.foregroundColor: UIColor.darkGray])

        contentNode.configure(with: term)
        self.item = item
    }
    
    // MARK: Lifecycle methods
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        var stack: [ASLayoutSpec] = []
        if let `item` = item, item.needsHeader {
            let backgroundNode = ASDisplayNode().then { $0.backgroundColor = .darkGray }
            stack.append(
                [ASDisplayNode(), headerTextNode, ASDisplayNode()]
                .stacked(.vertical)
                .then { $0.spacing = 8 }
                .insets(.left(8))
                .background(with: backgroundNode)
            )
        }
        
        stack.append(
            titleTextNode.insets(.all(16))
            .overlayed(by: contentNode)
            .overlayed(by: canvasNode)
            .overlayed(by: [editButtonNode, deleteButtonNode].stacked(in: .horizontal, spacing: 16, justifyContent: .end, alignItems: .start).insets(UIEdgeInsets.all(16)))
            .then { $0.style.flexGrow = 1  }
        )
        
        return stack.stacked(.vertical)
    }
    
    override func animateLayoutTransition(_ context: ASContextTransitioning) {}
}

// MARK: Operations

extension ASMedicalTermCellNode {
    func expand() {
        guard let canvasView = canvasNode.view as? CanvasView else { return }
        guard style.preferredSize.height < maximumHeight else { return }
        style.preferredSize.height = min(max((item?.lines.highestY ?? 0) + 200, style.preferredSize.height), maximumHeight)
        transitionLayout(withAnimation: false, shouldMeasureAsync: false) {
            canvasView.setNeedsDisplay()
        }
    }
    
    func contract(type: [(indexPath: IndexPath?, interactionType: ASAwareTableNode.InteractionType)]) {
        guard let canvasView = canvasNode.view as? CanvasView else { return }
        guard let `item` = item, !item.isPadder else { return }
        guard let tableNode = owningNode as? ASAwareTableNode else { return }
        let offset = tableNode.contentOffset
        let newHeight = min(max((item.lines.highestY ?? 0) + 4, item.needsHeader ? item.heightWithHeader : item.height), maximumHeight)
        style.preferredSize.height = newHeight
        print("buffer: \(type)")
        transitionLayout(withAnimation: false, shouldMeasureAsync: true) {
            canvasView.setNeedsDisplay()
            if type.contains(where: { (result) -> Bool in result.indexPath == self.indexPath && result.interactionType == .scribble }), let indexPath = self.indexPath, let tableNode = self.owningNode as? ASAwareTableNode {
                print("indexPath: \(indexPath)")
                tableNode.endContractSubject.onNext(HomeViewModel.IndexPathWithHeight(indexPath: indexPath, height: newHeight))
            }
            tableNode.setContentOffset(CGPoint(x: 0, y: min(offset.y, tableNode.view.contentSize.height)), animated: false)
        }
    }
}

extension ASMedicalTermCellNode {
    var linesChanged: Observable<(lines: [Line], indexPath: IndexPath)> {
        guard let canvasView = canvasNode.view as? CanvasView else { return .empty() }
        return canvasView.rx.lines.map { [unowned self] lines in
            guard let indexPath = self.indexPath else { throw NSError(domain: "CanvasView", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find indexPath"]) }
            return (lines: lines, indexPath: indexPath)
        }
    }
}
