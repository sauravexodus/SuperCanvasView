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
    
    var header: String?
    let maximumHeight: CGFloat = 300
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
    
    func configure(with item: ConsultationRow) {
        guard let term = item.medicalTerm as? ContentNode.RepresentationTarget else {
            print("Something has gone horribly, horribly awry...")
            return
        }
        header = item.header
        style.preferredSize.height = .init(item.height)
        canvasNode.style.preferredSize.height = .init(item.height)
        titleTextNode.attributedText = .init(string: term.name ?? "", attributes: [.foregroundColor: UIColor.darkGray])
        
        contentNode.configure(with: term)
    }
    
    // MARK: Lifecycle methods
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let insets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        let titleSpec = ASRelativeLayoutSpec(horizontalPosition: .start,
                                                verticalPosition: .start,
                                                sizingOption: [],
                                                child: titleTextNode)

        let contentSpec = ASRelativeLayoutSpec(horizontalPosition: .start,
                                                verticalPosition: .start,
                                                sizingOption: [],
                                                child: contentNode)

        let layoutspec = ASStackLayoutSpec.vertical()
        layoutspec.children = [titleSpec, contentSpec]
        
        return ASOverlayLayoutSpec(
            child: ASInsetLayoutSpec(insets: insets, child: titleSpec),
            overlay: canvasNode
        )
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
        style.preferredSize.height = min(canvasView.highestY + 200, maximumHeight)
        transitionLayout(withAnimation: false, shouldMeasureAsync: false) {
            canvasView.setNeedsDisplay()
        }
    }
    
    func contract() {
        guard let canvasView = canvasNode.view as? CanvasView else { return }
        let newHeight = min(style.preferredSize.height, max(titleTextNode.frame.height, canvasView.highestY + 2, 50))
        style.preferredSize.height = newHeight
        transitionLayout(withAnimation: false, shouldMeasureAsync: true) {
            canvasView.setNeedsDisplay()
            if let indexPath = self.indexPath, let tableNode = self.owningNode as? ASAwareTableNode {
                tableNode.endContractSubject.onNext(HomeViewModel.IndexPathWithHeight(indexPath: indexPath, height: newHeight))
            }
        }
    }
}
