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
        guard let canvasView = canvasNode.view as? CanvasView else { return }
        guard style.preferredSize.height < maximumHeight else { return }
        UIView.setAnimationsEnabled(false)
        style.preferredSize.height = min(max(canvasView.highestY + 30, style.preferredSize.height), maximumHeight)
        transitionLayout(withAnimation: false, shouldMeasureAsync: false) {
            canvasView.setNeedsDisplay()
        }
        Observable<Int>.timer(0.1, scheduler: MainScheduler.instance)
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
