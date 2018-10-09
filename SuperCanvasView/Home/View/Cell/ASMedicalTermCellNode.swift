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

final class ASMedicalTermCellNode: ASCellNode {
    
    let titleTextNode = ASTextNode().then {
        $0.maximumNumberOfLines = 0
    }
    
    let canvasNode = ASDisplayNode {
        CanvasView().then { $0.backgroundColor = .clear }
    }

    let headerTextNode = ASTextNode().then {
        $0.maximumNumberOfLines = 0
        $0.backgroundColor = .darkGray
    }
    
    var height: CGFloat
    var headerText: String?
    let disposeBag = DisposeBag()
    
    // MARK: Init methods
    
    init(height: CGFloat, headerText: String? = nil) {
        self.height = height
        self.headerText = headerText
        super.init()
        backgroundColor = .white
        style.preferredSize.height = height
        automaticallyManagesSubnodes = true
        canvasNode.style.preferredSize.height = height
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
                self.style.preferredSize.height = canvasView.highestY + 200
                self.transitionLayout(withAnimation: false, shouldMeasureAsync: false) {
                    canvasView.setNeedsDisplay()
                }
            })
            .disposed(by: disposeBag)

        Observable.merge(tapObservable, canvasView.rx.pencilDidStopMoving)
            .bind(to: tableNode.endUpdateSubject)
            .disposed(by: disposeBag)
        
        tableNode.endUpdateSubject.debounce(1, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let strongSelf = self else { return }
                UIView.setAnimationsEnabled(true)
                strongSelf.style.preferredSize.height = max(strongSelf.titleTextNode.frame.height, canvasView.highestY + 2, 50)
                strongSelf.transitionLayout(withAnimation: false, shouldMeasureAsync: true) {
                    canvasView.setNeedsDisplay()
                }
            })
            .disposed(by: disposeBag)
    }

    func configure(with text: String?, and lines: [Line]) {
        titleTextNode.attributedText = NSAttributedString(string: text ?? "", attributes: [NSAttributedStringKey.foregroundColor: UIColor.darkGray])
    }
    
    // MARK: Lifecycle methods
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let insets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        let relativeSpec = ASRelativeLayoutSpec(horizontalPosition: .start,
                                                verticalPosition: .start,
                                                sizingOption: [],
                                                child: titleTextNode)
        return ASOverlayLayoutSpec(
            child: ASInsetLayoutSpec(insets: insets, child: relativeSpec),
            overlay: canvasNode
        )
    }
    
    override func animateLayoutTransition(_ context: ASContextTransitioning) {
        
    }
}
