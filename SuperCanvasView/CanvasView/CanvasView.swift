//
//  CanvasView.swift
//  DocTalkEMR
//
//  Created by Ajay Mann on 5/14/18.
//  Copyright © 2018 DocTalk Solutions Pvt. Ltd. All rights reserved.
//
import Foundation
import UIKit
import RxSwift
import RxCocoa
import RxSwiftExt

enum CanvasTool {
    case pencil
    case eraser
}

enum PencilAction {
    case draw(Line, index: Int)
    case erase(Line, index: Int)
}

enum CanvasAction {
    case undo
    case redo
    case clear
}

class CanvasView: UIView {
    
    // MARK: Properties
    
    let isPredictionEnabled = UIDevice.current.userInterfaceIdiom == .pad
    let isTouchUpdatingEnabled = true
    
    var usePreciseLocations = false {
        didSet {
            needsFullRedraw = true
            setNeedsDisplay()
        }
    }
    var needsFullRedraw = true
    
    var canvasTool: CanvasTool = .pencil
    
    /// Array containing all line objects that need to be drawn in `drawRect(_:)`.
    var lines = [Line]()
    
    /// Array containing all line objects that have been completely drawn into the frozenContext.
    var finishedLines = [Line]()
    
    /// Array containing all actions performed on the canvas that can be undone
    var undoableActions = [PencilAction]()
    
    /// Array containing undone actions performed on the canvas that can be redone
    var redoableActions = [PencilAction]()
    
    /// Highest Y coodinate value among all points on the canvas
    var highestY: CGFloat = 0
    
    fileprivate var _highestYBehaviorSubject: BehaviorSubject<CGFloat>?
    /// Optimized version used for observing content offset changes.
    internal var highestYBehaviorSubject: BehaviorSubject<CGFloat> {
        if let subject = _highestYBehaviorSubject {
            return subject
        }
        
        let subject = BehaviorSubject<CGFloat>(value: self.highestY)
        _highestYBehaviorSubject = subject
        
        return subject
    }
    
    /**
     Holds a map of `UITouch` objects to `Line` objects whose touch has not ended yet.
     
     Use `NSMapTable` to handle association as `UITouch` doesn't conform to `NSCopying`. There is no value
     in accessing the properties of the touch used as a key in the map table. `UITouch` properties should
     be accessed in `NSResponder` callbacks and methods called from them.
     */
    let activeLines = NSMapTable<AnyObject, AnyObject>.strongToStrongObjects()
    
    /**
     Holds a map of `UITouch` objects to `Line` objects whose touch has ended but still has points awaiting
     updates.
     
     Use `NSMapTable` to handle association as `UITouch` doesn't conform to `NSCopying`. There is no value
     in accessing the properties of the touch used as a key in the map table. `UITouch` properties should
     be accessed in `NSResponder` callbacks and methods called from them.
     */
    let pendingLines = NSMapTable<AnyObject, AnyObject>.strongToStrongObjects()
    
    /// A `CGContext` for drawing the last representation of lines no longer receiving updates into.
    lazy var frozenContext: CGContext = {
        let scale = self.window!.screen.scale
        var size = self.bounds.size
        
        size.width *= scale
        size.height *= scale
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        context!.setLineCap(.round)
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        context!.concatenate(transform)
        
        return context!
    }()
    
    /// An optional `CGImage` containing the last representation of lines no longer receiving updates.
    var frozenImage: CGImage?
    
    // MARK: Touches
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if case .eraser = canvasTool {
            eraseLines(touches, withEvent: event)
            return
        }
        drawTouches(touches, withEvent: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if case .eraser = canvasTool {
            eraseLines(touches, withEvent: event)
            return
        }
        drawTouches(touches, withEvent: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if case .eraser = canvasTool {
            eraseLines(touches, withEvent: event)
            return
        }
        drawTouches(touches, withEvent: event)
        endTouches(touches, cancel: false)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if case .eraser = canvasTool { return }
        endTouches(touches, cancel: true)
    }
    
    override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {
        if case .eraser = canvasTool { return }
        updateEstimatedPropertiesForTouches(touches)
    }
    
    // MARK: Drawing
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        
        context.setLineCap(.round)
        
        if (needsFullRedraw) {
            setFrozenImageNeedsUpdate()
            frozenContext.clear(bounds)
            for array in [finishedLines, lines] {
                for line in array {
                    line.drawCommitedPointsInContext(frozenContext, usePreciseLocation: usePreciseLocations)
                }
            }
            needsFullRedraw = false
        }
        
        frozenImage = frozenImage ?? frozenContext.makeImage()
        
        if let frozenImage = frozenImage {
            context.draw(frozenImage, in: bounds)
        }
        
        for line in lines {
            line.drawInContext(context, usePreciseLocation: usePreciseLocations)
        }
    }
    
    func setFrozenImageNeedsUpdate() {
        frozenImage = nil
    }
    
    // MARK: Erasing
    
    func eraseLines(_ touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            // Skip over finger touches
            guard touch.type == .stylus else { continue }
            let location = touch.location(in: self)
            if let index = lines.index(where: { line in line.nearLocation(location: location) }) {
                redoableActions.removeAll()
                undoableActions.append(.erase(lines.remove(at: index), index: index))
                setNeedsDisplay()
            }
        }
    }
    
    // MARK: Actions
    
    func pencil() {
        canvasTool = .pencil
    }
    
    func erase() {
        canvasTool = .eraser
    }
    
    func undo() {
        if let action = undoableActions.popLast() {
            if case let .draw(line, index) = action {
                lines.remove(at: index)
                redoableActions.append(.erase(line, index: index))
            } else if case let .erase(line, index) = action {
                lines.insert(line, at: index)
                redoableActions.append(.draw(line, index: index))
            }
            setNeedsDisplay()
        }
    }
    
    func redo() {
        if let action = redoableActions.popLast() {
            if case let .draw(line, index) = action {
                lines.remove(at: index)
                undoableActions.append(.erase(line, index: index))
            } else if case let .erase(line, index) = action {
                lines.insert(line, at: index)
                undoableActions.append(.draw(line, index: index))
            }
            setNeedsDisplay()
        }
    }
    
    func clear() {
        activeLines.removeAllObjects()
        pendingLines.removeAllObjects()
        lines.removeAll()
        finishedLines.removeAll()
        undoableActions.removeAll()
        redoableActions.removeAll()
        updateHighestY()
        needsFullRedraw = true
        setNeedsDisplay()
    }

    // MARK: Convenience
    
    func drawTouches(_ touches: Set<UITouch>, withEvent event: UIEvent?) {
        var updateRect = CGRect.null
        for touch in touches {
            // Skip over finger touches
            guard touch.type == .stylus else { continue }
            
            // Retrieve a line from `activeLines`. If no line exists, create one.
            let line = activeLines.object(forKey: touch) as? Line ?? addActiveLineForTouch(touch)
            
            /*
             Remove prior predicted points and update the `updateRect` based on the removals. The touches
             used to create these points are predictions provided to offer additional data. They are stale
             by the time of the next event for this touch.
             */
            updateRect = updateRect.union(line.removePointsWithType(.Predicted))
            
            /*
             Incorporate coalesced touch data. The data in the last touch in the returned array will match
             the data of the touch supplied to `coalescedTouchesForTouch(_:)`
             */
            let coalescedTouches = event?.coalescedTouches(for: touch) ?? []
            let coalescedRect = addPointsOfType(.Coalesced, forTouches: coalescedTouches, toLine: line, currentUpdateRect: updateRect)
            updateRect = updateRect.union(coalescedRect)
            
            /*
             Incorporate predicted touch data. This sample draws predicted touches differently; however,
             you may want to use them as inputs to smoothing algorithms rather than directly drawing them.
             Points derived from predicted touches should be removed from the line at the next event for
             this touch.
             */
            if isPredictionEnabled {
                let predictedTouches = event?.predictedTouches(for: touch) ?? []
                let predictedRect = addPointsOfType(.Predicted, forTouches: predictedTouches, toLine: line, currentUpdateRect: updateRect)
                updateRect = updateRect.union(predictedRect)
            }
        }
        
        setNeedsDisplay(updateRect)
    }
    
    func addActiveLineForTouch(_ touch: UITouch) -> Line {
        let newLine = Line()
        activeLines.setObject(newLine, forKey: touch)
        lines.append(newLine)
        redoableActions.removeAll()
        undoableActions.append(.draw(newLine, index: lines.count - 1))
        return newLine
    }
    
    func addPointsOfType(_ type: LinePoint.PointType, forTouches touches: [UITouch], toLine line: Line, currentUpdateRect updateRect: CGRect) -> CGRect {
        var accumulatedRect = CGRect.null
        var type = type
        
        for (idx, touch) in touches.enumerated() {
            // Touches with estimated properties require updates; add this information to the `PointType`.
            if isTouchUpdatingEnabled && !touch.estimatedProperties.isEmpty {
                type.formUnion(.NeedsUpdate)
            }
            
            // The last touch in a set of `.Coalesced` touches is the originating touch. Track it differently.
            if type.contains(.Coalesced) && idx == touches.count - 1 {
                type.subtract(.Coalesced)
                type.formUnion(.Standard)
            }
            
            let touchRect = line.addPointOfType(type, forTouch: touch)
            accumulatedRect = accumulatedRect.union(touchRect)
            
            commitLine(line)
        }
        
        highestY = max(highestY, line.highestY)
        
        return updateRect.union(accumulatedRect)
    }
    
    func updateHighestY() {
        highestY = lines.map { $0.highestY }.sorted()
            .last ?? 0
        highestYBehaviorSubject.onNext(highestY)
    }
    
    func endTouches(_ touches: Set<UITouch>, cancel: Bool) {
        var updateRect = CGRect.null
        
        for touch in touches {
            // Skip over touches that do not correspond to an active line.
            guard let line = activeLines.object(forKey: touch) as? Line else { continue }
            
            // If this is a touch cancellation, cancel the associated line.
            if cancel { updateRect = updateRect.union(line.cancel()) }
            
            // If the line is complete (no points needing updates) or updating isn't enabled, move the line to the `frozenImage`.
            if line.isComplete || !isTouchUpdatingEnabled {
                finishLine(line)
            }
                // Otherwise, add the line to our map of touches to lines pending update.
            else {
                pendingLines.setObject(line, forKey: touch)
            }
            
            // This touch is ending, remove the line corresponding to it from `activeLines`.
            activeLines.removeObject(forKey: touch)
        }
        
        setNeedsDisplay(updateRect)
    }
    
    func updateEstimatedPropertiesForTouches(_ touches: Set<NSObject>) {
        guard isTouchUpdatingEnabled, let touches = touches as? Set<UITouch> else { return }
        
        for touch in touches {
            var isPending = false
            
            // Look to retrieve a line from `activeLines`. If no line exists, look it up in `pendingLines`.
            let possibleLine: Line? = activeLines.object(forKey: touch) as? Line ?? {
                let pendingLine = pendingLines.object(forKey: touch) as? Line
                isPending = pendingLine != nil
                return pendingLine
                }()
            
            // If no line is related to the touch, return as there is no additional work to do.
            guard let line = possibleLine else { return }
            
            switch line.updateWithTouch(touch) {
            case (true, let updateRect):
                setNeedsDisplay(updateRect)
            default:
                ()
            }
            
            // If this update updated the last point requiring an update, move the line to the `frozenImage`.
            if isPending && line.isComplete {
                finishLine(line)
                pendingLines.removeObject(forKey: touch)
            }
                // Otherwise, have the line add any points no longer requiring updates to the `frozenImage`.
            else {
                commitLine(line)
            }
            
        }
    }
    
    func commitLine(_ line: Line) {
        // Have the line draw any segments between points no longer being updated into the `frozenContext` and remove them from the line.
        line.drawFixedPointsInContext(frozenContext, usePreciseLocation: usePreciseLocations)
        setFrozenImageNeedsUpdate()
    }
    
    func finishLine(_ line: Line) {
        // Have the line draw any remaining segments into the `frozenContext`. All should be fixed now.
        line.drawFixedPointsInContext(frozenContext, usePreciseLocation: usePreciseLocations, commitAll: true)
        setFrozenImageNeedsUpdate()
        
        // Cease tracking this line now that it is finished.
        lines.remove(at: lines.index(of: line)!)
        
        // Store into finished lines to allow for a full redraw on option changes.
        finishedLines.append(line)
    }
}

extension Reactive where Base: CanvasView {
    
    var tool: Binder<CanvasTool> {
        return Binder(base) { target, tool in
            switch tool {
            case .pencil: target.pencil()
            case .eraser: target.erase()
            }
        }
    }
    
    var action: Binder<CanvasAction> {
        return Binder(base) { target, action in
            switch action {
            case .undo: target.undo()
            case .redo: target.redo()
            case .clear: target.clear()
            }
        }
    }
    
    /// Reactive wrapper for `highestY`.
    internal var highestY: ControlEvent<CGFloat> {
        let source = base.highestYBehaviorSubject
        return ControlEvent(events: source)
    }
    
    internal var lines: ControlProperty<[Line]> {
        return ControlProperty(
            values: Observable.merge(
                self.methodInvoked(#selector(Base.setNeedsDisplay(_:))).debounce(0.1, scheduler: MainScheduler.instance),
                self.methodInvoked(#selector(Base.setNeedsDisplay as (Base) -> () -> Void)))
                .debounce(0.1, scheduler: MainScheduler.instance).map { _ in self.base.lines },
            valueSink: Binder.init(base, binding: { (target, value) in
                target.lines = value
                target.updateHighestY()
                target.setNeedsDisplay()
            }))
    }
    
    internal var undoableActions: ControlProperty<[PencilAction]> {
        return ControlProperty(
            values: lines.map { _ in
                self.base.undoableActions },
            valueSink: Binder.init(base, binding: { (target, value) in
                target.undoableActions = value
            }))
    }
    
    internal var redoableActions: ControlProperty<[PencilAction]> {
        return ControlProperty(
            values: lines.map { _ in
                self.base.redoableActions },
            valueSink: Binder.init(base, binding: { (target, value) in
                target.redoableActions = value
            }))
    }
    
    var pencilTouchStarted: Observable<Void> {
        return self.methodInvoked(#selector(Base.touchesBegan(_:with:))).map { $0[0] as? Set<UITouch> }
            .unwrap()
            .filter { $0.contains(where: { $0.type == .stylus }) }
            .mapTo(())
    }
}

extension PencilAction: Equatable {
}

func ==(lhs: PencilAction, rhs: PencilAction) -> Bool {
    switch (lhs, rhs) {
    case (let .draw(line, index), let .draw(line2, index2)):
        return line == line2 && index == index2
    case (let .erase(line, index), let .erase(line2, index2)):
        return line == line2 && index == index2
    default:
        return false
    }
}
