//
//  Line.swift
//  DocTalkEMR
//
//  Created by Ajay Mann on 5/14/18.
//  Copyright © 2018 DocTalk Solutions Pvt. Ltd. All rights reserved.
//

import Foundation
import UIKit

extension CGPoint {
    func distanceToPoint(otherPoint: CGPoint) -> CGFloat {
        return sqrt(pow((otherPoint.x - x), 2) + pow((otherPoint.y - y), 2))
    }
}

extension Array where Element: Line {
    var highestY: CGFloat? {
        return map { $0.highestY }.sorted(by: >).first
    }
}

class Line: NSObject, Codable {
    enum CodingKeys: String, CodingKey {
        case p
    }
    
    // MARK: Properties
    // The live line.
    var points = [LinePoint]()
    
    // Use the estimation index of the touch to track points awaiting updates.
    var pointsWaitingForUpdatesByEstimationIndex = [NSNumber: LinePoint]()
    
    // Points already drawn into 'frozen' representation of this line.
    var committedPoints = [LinePoint]()
    
    // MARK: Computed properties
    
    // Highest Y coordinate value among all points in the line
    var highestY: CGFloat {
        get {
            return points.map { $0.preciseLocation.y }
                .sorted()
                .last ?? 0
        }
        set {  }
    }
    
    var isComplete: Bool {
        return pointsWaitingForUpdatesByEstimationIndex.isEmpty
    }
    
    // MARK: Init methods
    
    override init() { }
    
    // MARK: Codable
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(points, forKey: .p)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        points = try container.decode(Array<LinePoint>.self, forKey: .p)
    }
    
    // MARK: Instance methods
    
    func nearLocation(location: CGPoint) -> Bool {
        return points.contains { point in point.withinErasableDistance(location: location) }
    }
    
    func updateWithTouch(_ touch: UITouch) -> (Bool, CGRect) {
        if  let estimationUpdateIndex = touch.estimationUpdateIndex,
            let point = pointsWaitingForUpdatesByEstimationIndex[estimationUpdateIndex] {
            let rect = updateRectForExistingPoint(point)
            let didUpdate = point.updateWithTouch(touch)
            if didUpdate {
                rect.union(updateRectForExistingPoint(point))
            }
            if point.estimatedPropertiesExpectingUpdates == [] {
                pointsWaitingForUpdatesByEstimationIndex.removeValue(forKey: estimationUpdateIndex)
            }
            return (didUpdate, rect)
        }
        return (false, CGRect.null)
    }
    
    func addPointOfType(_ pointType: LinePoint.PointType, forTouch touch: UITouch) -> CGRect {
        let previousPoint = points.last
        let previousSequenceNumber = previousPoint?.sequenceNumber ?? -1
        let point = LinePoint(touch: touch, sequenceNumber: previousSequenceNumber + 1, pointType: pointType)
        
        if let estimationIndex = point.estimationUpdateIndex {
            if !point.estimatedPropertiesExpectingUpdates.isEmpty {
                pointsWaitingForUpdatesByEstimationIndex[estimationIndex] = point
            }
        }
        points.append(point)
        
        let updateRect = updateRectForLinePoint(point, previousPoint: previousPoint)
        
        return updateRect
    }
    
    func removePointsWithType(_ type: LinePoint.PointType) -> CGRect {
        var updateRect = CGRect.null
        var priorPoint: LinePoint?
        
        points = points.filter { point in
            let keepPoint = !point.pointType.contains(type)
            
            if !keepPoint {
                var rect = self.updateRectForLinePoint(point)
                
                if let priorPoint = priorPoint {
                    rect = rect.union(updateRectForLinePoint(priorPoint))
                }
                
                updateRect = updateRect.union(rect)
            }
            
            priorPoint = point
            
            return keepPoint
        }
        
        return updateRect
    }
    
    func cancel() -> CGRect {
        // Process each point in the line and accumulate the `CGRect` containing all the points.
        let updateRect = points.reduce(CGRect.null) { accumulated, point in
            // Update the type set to include `.Cancelled`.
            point.pointType.formUnion(.Cancelled)
            
            /*
             Union the `CGRect` for this point with accumulated `CGRect` and return it. The result is
             supplied to the next invocation of the closure.
             */
            return accumulated.union(updateRectForLinePoint(point))
        }
        
        return updateRect
    }
    
    // MARK: Drawing
    
    func drawInContext(_ context: CGContext, usePreciseLocation: Bool) {
        if let path = UIBezierPath(catmullRomInterpolatedPoints: points.filter { $0.pointType.contains(.Predicted) || $0.pointType.contains(.Standard) }.map { $0.preciseLocation }, closed: false, alpha: 0.5)?.cgPath {
            context.setStrokeColor(UIColor.black.cgColor)
            context.setLineWidth(2.5)
            context.beginPath()
            context.addPath(path)
            context.strokePath()
        }
    }
    
    func drawFixedPointsInContext(_ context: CGContext, usePreciseLocation: Bool, commitAll: Bool = false) {
        let allPoints = points
        var committing = [LinePoint]()
        
        if commitAll {
            committing = allPoints
            points.removeAll()
        } else {
            for (index, point) in allPoints.enumerated() {
                // Only points whose type does not include `.NeedsUpdate` or `.Predicted` and are not last or prior to last point can be committed.
                guard point.pointType.intersection([.NeedsUpdate, .Predicted]).isEmpty && index < allPoints.count - 2 else {
                    committing.append(points.first!)
                    break
                }
                
                guard index > 0 else { continue }
                
                // First time to this point should be index 1 if there is a line segment that can be committed.
                let removed = points.removeFirst()
                committing.append(removed)
            }
        }
        // If only one point could be committed, no further action is required. Otherwise, draw the `committedLine`.
        guard committing.count > 1 else { return }
        
        let committedLine = Line()
        committedLine.points = committing
        committedLine.drawInContext(context, usePreciseLocation: usePreciseLocation)
        
        if !committedPoints.isEmpty {
            // Remove what was the last point committed point; it is also the first point being committed now.
            committedPoints.removeLast()
        }
        
        // Store the points being committed for redrawing later in a different style if needed.
        committedPoints.append(contentsOf: committing)
    }
    
    func drawCommitedPointsInContext(_ context: CGContext, usePreciseLocation: Bool) {
        let committedLine = Line()
        committedLine.points = committedPoints
        committedLine.drawInContext(context, usePreciseLocation: usePreciseLocation)
    }
    
    // MARK: Convenience
    
    func updateRectForLinePoint(_ point: LinePoint) -> CGRect {
        var rect = CGRect(origin: point.preciseLocation, size: CGSize.zero)
        
        // The negative magnitude ensures an outset rectangle.
        let magnitude = -3 * point.magnitude - 2
        rect = rect.insetBy(dx: magnitude, dy: magnitude)
        
        return rect
    }
    
    func updateRectForLinePoint(_ point: LinePoint, previousPoint optionalPreviousPoint: LinePoint? = nil) -> CGRect {
        var rect = CGRect(origin: point.preciseLocation, size: CGSize.zero)
        
        var pointMagnitude = point.magnitude
        
        if let previousPoint = optionalPreviousPoint {
            pointMagnitude = max(pointMagnitude, previousPoint.magnitude)
            rect = rect.union(CGRect(origin: previousPoint.preciseLocation, size: CGSize.zero))
        }
        
        // The negative magnitude ensures an outset rectangle.
        let magnitude = -3.0 * pointMagnitude - 2.0
        rect = rect.insetBy(dx: magnitude, dy: magnitude)
        
        return rect
    }
    
    func updateRectForExistingPoint(_ point: LinePoint) -> CGRect {
        var rect = updateRectForLinePoint(point)
        
        let arrayIndex = point.sequenceNumber - points.first!.sequenceNumber
        
        if arrayIndex > 0 {
            rect = rect.union(updateRectForLinePoint(point, previousPoint: points[arrayIndex-1]))
        }
        if arrayIndex + 1 < points.count {
            rect = rect.union(updateRectForLinePoint(point, previousPoint: points[arrayIndex+1]))
        }
        return rect
    }
    
}

class LinePoint: NSObject, Codable {
    
    // MARK: Property Names
    enum PropertyNames: String {
        case sequenceNumber
        case preciseLocationXPoint
        case preciseLocationYPoint
        case estimatedPropertiesExpectingUpdates
        case type
        case estimationUpdateIndex
        case pointType
    }
    
    enum CodingKeys: String, CodingKey {
        case s
        case x
        case y
    }
    
    struct PointType: OptionSet, Codable {
        // MARK: Properties
        
        let rawValue: Int
        
        // MARK: Options
        
        static var Standard: PointType { return self.init(rawValue: 0) }
        static var Coalesced: PointType { return self.init(rawValue: 1 << 0) }
        static var Predicted: PointType { return self.init(rawValue: 1 << 1) }
        static var NeedsUpdate: PointType { return self.init(rawValue: 1 << 2) }
        static var Updated: PointType { return self.init(rawValue: 1 << 3) }
        static var Cancelled: PointType { return self.init(rawValue: 1 << 4) }
    }
    
    // MARK: Properties
    var sequenceNumber: Int
    var preciseLocation: CGPoint
    var estimatedPropertiesExpectingUpdates: UITouchProperties
    var estimatedProperties: UITouchProperties
    let type: UITouchType
    var estimationUpdateIndex: NSNumber? = nil
    var pointType: PointType
    
    // MARK: Computed properties
    var magnitude: CGFloat {
        return 2.5
    }
    
    // MARK: Init methods
    init(touch: UITouch, sequenceNumber: Int, pointType: PointType) {
        self.sequenceNumber = sequenceNumber
        let view = touch.view
        preciseLocation = touch.preciseLocation(in: view)
        estimatedPropertiesExpectingUpdates = touch.estimatedPropertiesExpectingUpdates
        estimatedProperties = touch.estimatedProperties
        self.type = touch.type
        self.pointType = pointType
        if !estimatedPropertiesExpectingUpdates.isEmpty {
            self.pointType.formUnion(.NeedsUpdate)
        }
        estimationUpdateIndex = touch.estimationUpdateIndex
    }
    
    // MARK: Codable
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sequenceNumber, forKey: .s)
        try container.encode(preciseLocation.x, forKey: .x)
        try container.encode(preciseLocation.y, forKey: .y)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sequenceNumber = try container.decode(Int.self, forKey: .s)
        let preciseLocationXPoint = try container.decode(CGFloat.self, forKey: .x)
        let preciseLocationYPoint = try container.decode(CGFloat.self, forKey: .y)
        preciseLocation = CGPoint(x: preciseLocationXPoint, y: preciseLocationYPoint)
        estimatedPropertiesExpectingUpdates = UITouchProperties()
        estimatedProperties = UITouchProperties()
        type = .stylus
        pointType = .Standard
    }
    
    // MARK: Instance methods
    
    //swiftlint:disable cyclomatic_complexity
    func updateWithTouch(_ touch: UITouch) -> Bool {
        guard let estimationUpdateIndex = touch.estimationUpdateIndex, estimationUpdateIndex == estimationUpdateIndex else { return false }
        
        // An array of the touch properties that may be of interest.
        let touchProperties: [UITouchProperties] = [.altitude, .azimuth, .force, .location]
        
        // Iterate through possible properties.
        for expectedProperty in touchProperties {
            // If an update to this property is not expected, continue to the next property.
            guard !estimatedPropertiesExpectingUpdates.contains(expectedProperty) else { continue }
            
            // Update the value of the point with the value from the touch's property.
            switch expectedProperty {
            case UITouchProperties.location:
                preciseLocation = touch.preciseLocation(in: touch.view)
            default:
                ()
            }
            
            if !touch.estimatedProperties.contains(expectedProperty) {
                // Flag that this point now has a 'final' value for this property.
                estimatedProperties.subtract(expectedProperty)
            }
            
            if !touch.estimatedPropertiesExpectingUpdates.contains(expectedProperty) {
                // Flag that this point is no longer expecting updates for this property.
                estimatedPropertiesExpectingUpdates.subtract(expectedProperty)
                
                if estimatedPropertiesExpectingUpdates.isEmpty {
                    // Flag that this point has been updated and no longer needs updates.
                    pointType.subtract(.NeedsUpdate)
                    pointType.formUnion(.Updated)
                }
            }
        }
        
        return true
    }
    //swiftlint:enable cyclomatic_complexity
    
    func withinErasableDistance(location: CGPoint) -> Bool {
        return self.preciseLocation.distanceToPoint(otherPoint: location) < 10
    }
}
