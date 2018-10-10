//
//  UIScrollView+extensions.swift
//  SuperCanvasView
//
//  Created by Vamsee Chamakura on 10/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import RxSwift

extension Reactive where Base: UIScrollView {
    func swCapture() -> Observable<UIImage?> {
        return Observable.create { [weak base] observer in
            guard let strongBase = base else {
                observer.onError(NSError.init(domain: "swCapture", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get base"]))
                return Disposables.create()
            }
            strongBase.swContentCapture({ (image) in
                observer.onNext(image)
                observer.onCompleted()
            })
            return Disposables.create()
        }
    }
}
