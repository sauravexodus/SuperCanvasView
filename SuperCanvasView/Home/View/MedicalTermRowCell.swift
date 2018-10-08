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

extension UIView {
    var frameInDisplay: CGRect {
        var frame = self.frame
        
        guard let superviewFrame = superview?.frame else {
            return frame
        }
        
        if frame.origin.x > 0 {
            let xExtension = (frame.origin.x + frame.size.width) - superviewFrame.width
            if xExtension > 0 {
                frame.size.width = superviewFrame.width - frame.origin.x
            }
        } else if frame.origin.x < 0 {
            let widthInDisplay = frame.size.width + frame.origin.x
            frame.size.width = min(widthInDisplay, superviewFrame.width)
        } else {
            frame.size.width = min(frame.width, superviewFrame.width)
        }
        
        if frame.origin.y > 0 {
            let yExtension = (frame.origin.y + frame.size.height) - superviewFrame.height
            if yExtension > 0 {
                frame.size.height = superviewFrame.height - frame.origin.y
            }
        } else if frame.origin.y < 0 {
            let heightInDisplay = frame.size.height + frame.origin.y
            frame.size.height = min(heightInDisplay, superviewFrame.height)
        } else {
            frame.size.height = min(frame.height, superviewFrame.height)
        }

        return frame
    }
}

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

final class MedicalTermRowCell: UITableViewCell, Reusable {
    var disposeBag = DisposeBag()
    
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
    
    override func prepareForReuse() {
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
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .white
        selectionStyle = .none

        canvasView.rx.pencilTouchDidNearBottom
            .map { [unowned self] _ in self.updateUI { self.expand(by: 200) } }
            .subscribe()
            .disposed(by: disposeBag)
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
            self.canvasView.rx.pencilDidStopMoving.map { [unowned self] in
                self.rx_wantsContract.onNext(())
                }
                .subscribe()
                .disposed(by: self.startDisposeBag)
            }
            .subscribe()
            .disposed(by: disposeBag)
    }
}

extension MedicalTermRowCell {
    func updateUI(_ f: @escaping () -> ()) {
        UIView.performWithoutAnimation {
            self.rx_didBeginUpdate.onNext(())
            f()
            self.rx_didEndUpdate.onNext(())
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
        
        if newHeight > .init(PDFPageSize.A4.height) {
            return
        }
        self.innerContentView.snp.updateConstraints { make in
            make.height.equalTo(newHeight)
        }

        if let lastCanvasViewHeight = lastCanvasViewHeight, lastCanvasViewHeight > newHeight {

        } else {
            self.canvasView.snp.updateConstraints { make in
                make.height.equalTo(newHeight)
            }

            lastCanvasViewHeight = newHeight
        }
        
        self.lastHeight = newHeight
    }
    
    func contract() {
        guard let initialHeight = initialHeight else {
            return
        }
        let newHeight = max(initialHeight, .init(canvasView.highestY + 10))

        self.innerContentView.snp.updateConstraints { make in
            make.height.equalTo(newHeight)
        }
        self.lastHeight = newHeight
    }
}
