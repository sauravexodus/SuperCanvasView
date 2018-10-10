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
        $0.backgroundColor = .darkGray
    }
    
    let editButtonNode = ASButtonNode().then {
        $0.setTitle("EDIT", with: UIFont.systemFont(ofSize: 12, weight: .semibold), with: .black, for: .normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }
    
    let deleteButtonNode = ASButtonNode().then {
        $0.setTitle("DELETE", with: UIFont.systemFont(ofSize: 12, weight: .semibold), with: .black, for: .normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }

    var headerText: String?
    let disposeBag = DisposeBag()
    
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
        
        Observable.merge(tapObservable, canvasView.rx.pencilDidStopMoving)
            .bind(to: tableNode.endUpdateSubject)
            .disposed(by: disposeBag)
        
        tableNode.endUpdateSubject.debounce(1, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] _ in
                UIView.setAnimationsEnabled(true)
                self.contract()
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
        
        style.preferredSize.height = .init(item.height)
        canvasNode.style.preferredSize.height = .init(item.height)
        titleTextNode.attributedText = .init(string: term.name ?? "", attributes: [.foregroundColor: UIColor.darkGray])
        
        contentNode.configure(with: term)
    }
    
    // MARK: Lifecycle methods
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return [
            titleTextNode.insets(.all(16)).relative(horizontalPosition: .start, verticalPosition: .start, sizingOption: []),
            contentNode.relative(horizontalPosition: .start, verticalPosition: .start, sizingOption: [])
            ]
            .stacked(.vertical)
            .overlayed(by: canvasNode)
            .overlayed(by: [editButtonNode, deleteButtonNode].stacked(in: .horizontal, spacing: 16, justifyContent: .end, alignItems: .start).insets(.all(16)))
    }
    
    override func animateLayoutTransition(_ context: ASContextTransitioning) {
        
    }
}

// MARK: Operations

extension ASMedicalTermCellNode {
    func expand() {
        guard let canvasView = canvasNode.view as? CanvasView else {
            return
        }
        style.preferredSize.height = canvasView.highestY + 200
        transitionLayout(withAnimation: false, shouldMeasureAsync: false) {
            canvasView.setNeedsDisplay()
        }
    }
    
    func contract() {
        guard let canvasView = canvasNode.view as? CanvasView else {
            return
        }
        style.preferredSize.height = max(titleTextNode.frame.height, canvasView.highestY + 2, 50, deleteButtonNode.frame.height + 32, contentNode.frame.height)
        transitionLayout(withAnimation: false, shouldMeasureAsync: true) {
            canvasView.setNeedsDisplay()
        }
    }
}
