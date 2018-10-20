//
//  ASMedicalTermCellNode+UI.swift
//  SuperCanvasView
//
//  Created by Sourav Chandra on 12/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import RxSwift


// MARK: Animations

protocol ExpandableCellNode {
    func expand()
    func contract(interactionType: ASAwareTableNode.InteractionType)
}

extension ASMedicalTermCellNode: ExpandableCellNode {
    func expand() {
        guard let canvasView = canvasNode.view as? CanvasView, let expansionProperties = item?.getHeightExpansionProperties(with: style.preferredSize.height), expansionProperties.needsToExpand else { return }
        UIView.setAnimationsEnabled(false)
        style.preferredSize.height = expansionProperties.expandedHeight
        transitionLayout(withAnimation: false, shouldMeasureAsync: false) {
            canvasView.setNeedsDisplay()
        }
        Observable<Int>.timer(0.2, scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in UIView.setAnimationsEnabled(true) })
            .disposed(by: disposeBag)
    }

    func contract(interactionType: ASAwareTableNode.InteractionType) {
        guard let canvasView = canvasNode.view as? CanvasView else { return }
        guard let `item` = item else { return }
        let newHeight = min(max((item.lines.highestY ?? 0), item.height), PageSize.selectedPage.heightRemovingMargins)
        style.preferredSize.height = newHeight
        transitionLayout(withAnimation: false, shouldMeasureAsync: true) {
            guard case .scribble = interactionType else { return }
            canvasView.setNeedsDisplay()
        }
    }
}

// MARK: Styling

extension ASMedicalTermCellNode {
    internal func setupUI() {
        setupCanvas()
        setupStyles()
    }
    
    private func setupCanvas() {
        guard let `item` = item, let canvasView = canvasNode.view as? CanvasView else { return }
        canvasView.lines = item.lines
        canvasView.setNeedsDisplay()
    }
    
    private func setupStyles() { }
}
