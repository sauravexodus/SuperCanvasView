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
        
        style.preferredSize.height = .init(item.height)
        canvasNode.style.preferredSize.height = .init(item.height)
        titleTextNode.attributedText = .init(string: item.medicalTerm.name ?? "", attributes: [.foregroundColor: UIColor.darkGray])
        
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
        style.preferredSize.height = canvasView.highestY + 200
        transitionLayout(withAnimation: false, shouldMeasureAsync: false) {
            canvasView.setNeedsDisplay()
        }
    }
    
    func contract() {
        guard let canvasView = canvasNode.view as? CanvasView else {
            return
        }
        style.preferredSize.height = max(titleTextNode.frame.height, canvasView.highestY + 2, 50)
        transitionLayout(withAnimation: false, shouldMeasureAsync: true) {
            canvasView.setNeedsDisplay()
        }
    }
}
