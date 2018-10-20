//
//  ASMedicalFormCellNode+binding.swift
//  SuperCanvasView
//
//  Created by Krishna C Aluru on 10/19/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import RxSwift

// MARK: Bindings

extension ASMedicalFormCellNode {
    var linesChanged: Observable<(lines: [Line], indexPath: IndexPath)> {
        guard let canvasView = canvasNode.view as? CanvasView else { return .empty() }
        return canvasView.rx.lines
            .distinctUntilChanged()
            .map { [weak self] lines in
                guard let indexPath = self?.indexPath else { throw NSError(domain: "CanvasView", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find indexPath"]) }
                return (lines: lines, indexPath: indexPath)
            }
            .catchErrorJustReturn(nil)
            .unwrap()
    }
    
    internal func bind() {
        bindCanvas()
        
        bindExpanding()
    }
    
    private func bindExpanding() {
        guard let canvasView = canvasNode.view as? CanvasView else { return }
        
        let tapObservable = rx.tapGesture { gesture, _ in
            gesture.allowedTouchTypes = [NSNumber(value: UITouchType.direct.rawValue)]
            }
            .mapTo(())
        
        Observable.merge(
            tapObservable,
            canvasView.rx.pencilTouchDidNearBottom)
            .subscribe(onNext: { [unowned self] _ in
                self.expand()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindCanvas() {
        guard let canvasView = canvasNode.view as? CanvasView else { return }
        canvasView.rx.lines.subscribe(onNext: { [weak self] lines in
            guard let strongSelf = self else { return }
            strongSelf.item?.lines = lines
        }).disposed(by: disposeBag)
        
        canvasView.rx.redoableActions
            .subscribe(onNext: { [weak self] redoableActions in
                guard
                    let owningNode = self?.owningNode as? ASAwareTableNode,
                    let indexPath = self?.indexPath,
                    redoableActions.count != owningNode.redoableActionsIndexes.filter({ $0 == indexPath }).count
                    else { return }
                owningNode.redoableActionsIndexes.append(indexPath)
            })
            .disposed(by: disposeBag)
        
        canvasView.rx.undoableActions
            .subscribe(onNext: { [weak self] undoableActions in
                guard
                    let owningNode = self?.owningNode as? ASAwareTableNode,
                    let indexPath = self?.indexPath,
                    undoableActions.count != owningNode.undoableActionsIndexes.filter({ $0 == indexPath }).count
                    else { return }
                owningNode.undoableActionsIndexes.append(indexPath)
            })
            .disposed(by: disposeBag)
    }
}

