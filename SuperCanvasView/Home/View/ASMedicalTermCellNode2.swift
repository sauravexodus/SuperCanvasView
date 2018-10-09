//
//  DiagnosisRowCell.swift
//  SuperCanvasView
//
//  Created by Krishna C Aluru on 10/7/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import UIKit
import Reusable
import RxSwift

extension Reactive where Base: MedicalTermRowCellNode {
    var didBeginWriting: Observable<Void> {
        return base.canvasView.rx.pencilTouchStarted
    }
    var wantsContract: Observable<Void> {
        return base.rx_wantsContract.asObservable()
    }
    var didBeginUpdate: Observable<Void> {
        return base.rx_didBeginUpdate.asObservable()
    }
    var didEndUpdate: Observable<Void> {
        return base.rx_didEndUpdate.asObservable()
    }
}

final class MedicalTermRowCellNode: UIView {
    var disposeBag = DisposeBag()
    
    var updateBlock: ((() -> ()) -> ())?
    
    fileprivate var rx_didBeginUpdate = PublishSubject<Void>()
    fileprivate var rx_didEndUpdate = PublishSubject<Void>()
    fileprivate var rx_wantsContract = PublishSubject<Void>()
    
    let innerContentView = UIView().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.clipsToBounds = true
    }
    
    let titleLabel = UILabel().then {
        $0.textColor = .black
    }
    
    let canvasView = CanvasView().then {
        $0.backgroundColor = .clear
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func prepareForReuse() {
        // Reset stored heights
        initialHeight = nil
        lastHeight = nil
        lastCanvasViewHeight = nil
        
        // Reset the background color
        backgroundColor = .white
        
        // Clear the canvas
        canvasView.clear()
        
        // Reset Constraints
        innerContentView.snp.removeConstraints()
        titleLabel.snp.removeConstraints()
        canvasView.snp.removeConstraints()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        canvasView.rx.pencilTouchDidNearBottom
            .map { [unowned self] _ in
                self.updateUI { [unowned self] in
                    self.expand(by: 200)
                }
            }
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var initialHeight: Float?
    var lastHeight: Float?
    var lastCanvasViewHeight: Float?
    
    var startDisposeBag = DisposeBag()
    
    func configure(with text: String?, and lines: [Line], height: Float) {
        initialHeight = height
        lastHeight = height
        titleLabel.text = text
        canvasView.lines = lines
        
        addSubview(innerContentView)
        innerContentView.addSubview(titleLabel)
        innerContentView.addSubview(canvasView)
        
        innerContentView.snp.remakeConstraints { make in
            make.height.equalTo(height)
            make.top.left.right.bottom.equalToSuperview().priority(.high)
        }
        
        titleLabel.snp.remakeConstraints { make in
            make.height.equalTo(height)
            make.top.left.right.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
            make.bottom.equalToSuperview().priority(.low)
        }
        
        canvasView.snp.remakeConstraints { make in
            make.height.equalTo(height)
            make.top.left.right.equalToSuperview()
        }
        
        canvasView.rx.pencilTouchStarted.map { [unowned self] in
            
            self.startDisposeBag = DisposeBag()
            
            self.canvasView.rx.pencilDidStopMoving
                .map { [unowned self] in
                    self.rx_wantsContract.onNext(())
                }
                .subscribe()
                .disposed(by: self.startDisposeBag)
            }
            
            .subscribe()
            .disposed(by: disposeBag)
    }
}

extension MedicalTermRowCellNode {
    func updateUI(_ f: @escaping () -> ()) {
        if let updateBlock = updateBlock {
            updateBlock {
                f()
            }
        } else {
            UIView.performWithoutAnimation {
                self.rx_didBeginUpdate.onNext(())
                f()
                self.rx_didEndUpdate.onNext(())
            }
        }
        /*UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [], animations: {
         self.rx_didBeginUpdate.onNext(())
         f()
         self.rx_didEndUpdate.onNext(())
         }, completion: nil)*/
    }
    
    func expand(by offset: Float) {
        guard let lastHeight = lastHeight else {
            return
        }
        
        let newHeight = lastHeight + offset
        
        setInnerContentViewHeight(to: newHeight)
        
        if let lastCanvasViewHeight = lastCanvasViewHeight, lastCanvasViewHeight > newHeight {
            // do nothing
        } else {
            setCanvasViewHeight(to: newHeight)
        }
    }
    
    func contract() {
        guard let initialHeight = initialHeight else {
            return
        }
        let newHeight = max(initialHeight, .init(canvasView.highestY + 10))
        setInnerContentViewHeight(to: newHeight)
    }
    
    func setInnerContentViewHeight(to height: Float) {
        self.innerContentView.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
        self.lastHeight = height
    }
    
    func setCanvasViewHeight(to height: Float) {
        self.canvasView.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
        lastCanvasViewHeight = height
    }
}
