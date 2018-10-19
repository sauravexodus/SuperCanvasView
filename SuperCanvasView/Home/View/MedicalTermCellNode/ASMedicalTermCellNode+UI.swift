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

extension ASMedicalTermCellNode {
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
