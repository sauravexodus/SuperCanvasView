//
//  MedicalTermRowCell.swift
//  SuperCanvasView
//
//  Created by Krishna C Aluru on 10/6/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import UIKit
import Reusable
import RxSwift

extension ObservableType {
    func ignoringErrors() -> Observable<E> {
        return self
            .map { Optional.some($0) }
            .catchErrorJustReturn(nil)
            .filter { $0 != nil }
            .map { $0! }
    }
    
    func timeoutNoError(_ duration: RxTimeInterval, scheduler: SchedulerType) -> Observable<Void> {
        return timeout(duration, scheduler: scheduler)
            .map({ _ in false })
            .catchError { error in
                guard let rxError = error as? RxError,
                    case RxError.timeout = rxError else {
                        return Observable.error(error)
                }
                return Observable.just(true)
            }
            .filter({ $0 })
            .mapTo(())
    }
}

extension Reactive where Base: MedicalTermRowCell {
    var didBeginUpdate: Observable<Void> {
        return base.beginUpdateCell.asObservable()
    }
    var didEndUpdate: Observable<Void> {
        return base.endUpdateCell.asObservable()
    }
}

final class MedicalTermRowCell: UITableViewCell, Reusable {
    var disposeBag = DisposeBag()
    var beginUpdateCell = PublishSubject<Void>()
    var endUpdateCell = PublishSubject<Void>()

    let innerContentView = UIView().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    let titleLabel = UILabel().then {
        $0.text = "Random text"
        $0.textColor = .black
    }
    
    let canvasView = CanvasView().then {
        $0.backgroundColor = .clear
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func prepareForReuse() {
        // Reset stored heights
        initialHeight = nil
        lastHeight = nil
        
        // Reset the background color
        backgroundColor = .white
        
        // Clear the canvas
        canvasView.clear()
        
        // Reset Constraints
        innerContentView.snp.removeConstraints()
        titleLabel.snp.removeConstraints()
        canvasView.snp.removeConstraints()
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .white
        selectionStyle = .none

        canvasView.rx.pencilTouchDidNearBottom
            .map { [unowned self] _ in self.expand(by: 100) }
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var initialHeight: Float?
    var lastHeight: Float?
    
    var startDisposeBag = DisposeBag()
    
    func configure(with text: String?, and lines: [Line], height: Float) {
        initialHeight = height
        lastHeight = height
        titleLabel.text = text
        canvasView.lines = lines
        addSubview(titleLabel)
        addSubview(canvasView)
        if text == "Symptom" { backgroundColor = .blue }
        if text == "Diagnosis" { backgroundColor = .red }
        titleLabel.snp.remakeConstraints { make in
            make.height.equalTo(height)
            make.top.left.right.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
            make.bottom.equalToSuperview().priority(.low)
        }
        canvasView.snp.remakeConstraints { make in
            make.height.equalTo(height)
            make.top.bottom.left.right.equalToSuperview()
        }
        
        canvasView.rx.pencilTouchStarted.map { [weak self] in
            guard let strongSelf = self else { return }
            if Float(strongSelf.frame.height) == strongSelf.initialHeight {
                strongSelf.expand(by: 100)
                strongSelf.startDisposeBag = DisposeBag()
                strongSelf.canvasView.rx.pencilDidStopMoving.map { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.contract()
                    }.subscribe().disposed(by: strongSelf.startDisposeBag)
            }
        }.subscribe().disposed(by: disposeBag)
    }
    
    func updateUI(_ f: @escaping () -> ()) {
        
        UIView.animate(withDuration: 0) {
            f()
            self.beginUpdateCell.onNext(())
            self.setNeedsLayout()
            self.layoutIfNeeded()
            self.endUpdateCell.onNext(())
        }
    }
    
    func expand(by offset: Float = 15) {
        guard let lastHeight = lastHeight else {
            return
        }
        let newHeight = lastHeight + offset
        
        updateUI {
            self.canvasView.snp.remakeConstraints { make in
                make.height.equalTo(newHeight)
                make.top.bottom.left.right.equalToSuperview().priority(.high)
            }
            self.lastHeight = newHeight
        }
    }
    
    func contract() {
        guard let initialHeight = initialHeight else {
            return
        }
        let newHeight = max(initialHeight, .init(canvasView.highestY))
        updateUI {
            self.canvasView.snp.remakeConstraints { make in
                make.height.equalTo(newHeight)
                make.top.bottom.left.right.equalToSuperview().priority(.high)
            }
            self.lastHeight = newHeight
        }
    }
}
