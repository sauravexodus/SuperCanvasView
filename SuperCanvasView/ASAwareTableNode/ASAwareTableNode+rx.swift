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
    
    var undo: Binder<Void> {
        return Binder(base, binding: { target, _ in
            target.undo()
        })
    }
    
    var redo: Binder<Void> {
        return Binder(base, binding: { target, _ in
            target.redo()
        })
    }
    
    var clear: Binder<Void> {
        return Binder(base, binding: { target, _ in
            target.clear()
        })
    }
    
    var canvasTool: Binder<CanvasTool> {
        return Binder(base, binding: { _, tool in
            ASAwareTableNode.canvasTool = tool
        })
    }
    
    var didScroll: ControlEvent<Void> {
        return ControlEvent(events: base.scrollSubject)
    }
}
