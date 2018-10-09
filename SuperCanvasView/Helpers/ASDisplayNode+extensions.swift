//
//  ASDisplayNode+extensions.swift
//  SuperCanvasView
//
//  Created by Vatsal Manot on 10/9/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import AsyncDisplayKit
import Foundation
import RxGesture
import RxSwift

extension Reactive where Base: ASDisplayNode {
    var tap: Observable<UITapGestureRecognizer> {
        return base.view.rx.tapGesture().when(.recognized)
    }
    
    func tapGesture(configuration: TapConfiguration?) -> Observable<UITapGestureRecognizer> {
        return base.view.rx.tapGesture(configuration: configuration).when(.recognized)
    }
}
