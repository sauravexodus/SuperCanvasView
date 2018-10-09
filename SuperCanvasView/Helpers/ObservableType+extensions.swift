//
//  ObservableType+extensions.swift
//  SuperCanvasView
//
//  Created by Vatsal Manot on 10/9/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
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
