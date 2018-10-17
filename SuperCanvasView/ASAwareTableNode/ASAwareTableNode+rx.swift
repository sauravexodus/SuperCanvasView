//
//  ASAwareTableNode+rx.swift
//  SuperCanvasView
//
//  Created by Sourav Chandra on 12/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

// MARK: Reactive Extensions

extension Reactive where Base: ASAwareTableNode {
    var linesUpdated: ControlProperty<LinesWithIndexPath> {
        return ControlProperty(values: base.linesUpdateSubject, valueSink: base.linesUpdateSubject)
    }
}
