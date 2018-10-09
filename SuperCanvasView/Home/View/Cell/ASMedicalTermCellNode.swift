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
    
    var height: CGFloat
    let disposeBag = DisposeBag()
    
    // MARK: Init methods
    
    init(height: CGFloat) {
        self.height = height
        super.init()
        backgroundColor = .white
        style.preferredSize.height = height
        automaticallyManagesSubnodes = true
        shouldAnimateSizeChanges = true
    }
    
    // MARK: Instance methods
    
    override func didLoad() {
        guard let canvasView = canvasNode.view as? CanvasView else { return }
        canvasView.rx.pencilTouchDidNearBottom
            .debug("Highest Y", trimOutput: true)
            .subscribe(onNext: { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.style.preferredSize.height += 200
                strongSelf.transitionLayout(withAnimation: true, shouldMeasureAsync: true)
            })
            .disposed(by: disposeBag)
        
        canvasView.rx.pencilDidStopMoving
            .debug("Highest Y", trimOutput: true)
            .subscribe(onNext: { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.style.preferredSize.height = max(300, canvasView.highestY + 50)
                strongSelf.transitionLayout(withAnimation: true, shouldMeasureAsync: true)
            })
            .disposed(by: disposeBag)
    }
    
    func configure(with text: String?, and lines: [Line]) {
        titleTextNode.attributedText = NSAttributedString(string: text ?? "", attributes: [NSAttributedStringKey.foregroundColor: UIColor.darkGray])
    }
    
    // MARK: Lifecycle methods
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let insets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        canvasNode.style.preferredSize = CGSize(width: .greatestFiniteMagnitude, height: height)
        return ASOverlayLayoutSpec(
            child: ASInsetLayoutSpec(insets: insets, child: titleTextNode),
            overlay: canvasNode
        )
    }
    
    override func animateLayoutTransition(_ context: ASContextTransitioning) {
        super.animateLayoutTransition(context)
    }
}
