//
//  ASMedicalTermCellNode+binding.swift
//  SuperCanvasView
//
//  Created by Sourav Chandra on 12/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import RxSwift

// MARK: Bindings

extension ASMedicalTermCellNode {
    
    var linesChanged: Observable<(lines: [Line], indexPath: IndexPath)> {
        guard let canvasView = canvasNode.view as? CanvasView else { return .empty() }
        return canvasView.rx.lines.map { [unowned self] lines in
            guard let indexPath = self.indexPath else { throw NSError(domain: "CanvasView", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find indexPath"]) }
            return (lines: lines, indexPath: indexPath)
        }
    }
    
    internal func bind() {
        bindEditAction()
        bindDeleteAction()
        bindCanvas()
        
        bindExpanding()
        bindContracting()
    }
    
    private func bindExpanding() {
        guard let canvasView = canvasNode.view as? CanvasView,
            let tableNode = owningNode as? ASAwareTableNode else { return }
        
        let tapObservable = rx.tapGesture { gesture, _ in
            gesture.allowedTouchTypes = [NSNumber(value: UITouchType.direct.rawValue)]
            }
            .mapTo(())
        
        Observable.merge(tapObservable,canvasView.rx.pencilTouchDidNearBottom)
            .subscribe(onNext: { [unowned self] _ in
                UIView.setAnimationsEnabled(false)
                self.expand()
            })
            .disposed(by: disposeBag)
        
        Observable.merge(tapObservable, canvasView.rx.pencilDidStopMoving)
            .bind(to: tableNode.rx.updatesEnded)
            .disposed(by: disposeBag)
    }
    
    private func bindContracting() {
        guard let tableNode = owningNode as? ASAwareTableNode else { return }
        tableNode.rx.updatesEnded
            .debounce(1.5, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] type in
                UIView.setAnimationsEnabled(true)
                self.contract()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindCanvas() {
        guard let canvasView = canvasNode.view as? CanvasView else { return }
        canvasView.rx.lines.subscribe(onNext: { [weak self] lines in
            guard let strongSelf = self else { return }
            strongSelf.item?.lines = lines
        })
            .disposed(by: disposeBag)
    }
    
    private func bindEditAction() {
        editButtonNode.rx.tap
            .subscribe(onNext: { _ in
                print("Edit Tapped")
            })
            .disposed(by: disposeBag)
    }
    
    private func bindDeleteAction() {
        deleteButtonNode.rx.tap
            .subscribe(onNext: { _ in
                print("Delete Tapped")
            })
            .disposed(by: disposeBag)
    }
}
