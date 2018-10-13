//
//  ConsultationRow.swift
//  SuperCanvasView
//
//  Created by Krishna C Aluru on 10/6/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import UIKit
import Differentiator

enum ASNodeRow {
    case medicalTerm(id: String, height: CGFloat, lines: [Line], medicalTermType: MedicalTermType)
    case pageBreak(id: String, pageNumber: Int)
    
    init(height: CGFloat, lines: [Line], medicalTerm: MedicalTermType) {
        self = .medicalTerm(id: UUID().uuidString, height: height, lines: lines, medicalTermType: medicalTerm)
    }
    
    var isPadder: Bool {
        switch self {
        case let .medicalTerm(_, _, lines, medicalTerm): return medicalTerm.name == nil && lines.isEmpty
        default: return false
        }
    }
    
    var medicalSection: MedicalSection {
        return medicalTerm.sectionOfSelf
    }
    
    var medicalTerm: MedicalTermType {
        switch self {
        case let .medicalTerm(_, _, _, medicalTerm): return medicalTerm
        default: fatalError("This is a page break row type!")
        }
    }
    
    var lines: [Line] {
        get {
            switch self {
            case let .medicalTerm(_, _, lines, _): return lines
            default: fatalError("This is a page break row type!")
            }
        }
        set {
            guard case let .medicalTerm(id, height, _, medicalTerm) = self else { fatalError("This is a page break!") }
            self = .medicalTerm(id: id, height: height, lines: newValue, medicalTermType: medicalTerm)
        }
    }
    
    var height: CGFloat {
        switch self {
        case let .medicalTerm(_, initialHeight, lines, medicalTerm):
            return min(max(NSAttributedString(string: medicalTerm.name ?? "").heightContrainedToA4, lines.highestY ?? 0, initialHeight), PageSize.A4.height)
        default: return 1
        }
    }
    
    var id: String {
        switch self {
        case let .medicalTerm(id, _, _, _): return id
        case let .pageBreak(pageNumber): return "Page break \(pageNumber)"
        }
    }
}

extension ASNodeRow: Hashable {
    
    static func == (lhs: ASNodeRow, rhs: ASNodeRow) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    var hashValue: Int {
        return id.hashValue
    }
}

extension ASNodeRow: IdentifiableType {
    typealias Identity = String
    
    var identity: String {
        return id
    }
}

extension Array where Element == Array<ASNodeRow> {
    func joined(separator element: ASNodeRow) -> [ASNodeRow] {
        return reduce([], { seed, acc in
            var mutable = seed
            mutable.append(contentsOf: acc)
            mutable.append(element)
            return mutable
        })
    }
    
    func joined() -> [ASNodeRow] {
        return reduce([], { seed, acc in
            var mutable = seed
            mutable.append(contentsOf: acc)
            return mutable
        })
    }
}

extension Array where Element == ASNodeRow {
    
    var height: CGFloat {
        return map { $0.height }.reduce(0, +)
    }
    
    func withPageBreaks(occupiedHeight: CGFloat) -> (items: [ASNodeRow], lastSectionOccupiedHeight: CGFloat) {
        let sectionedArray = split(occupiedHeight: occupiedHeight)
        let finalArray = sectionedArray.enumerated()
            .map { enumerator in
                guard enumerator.offset != sectionedArray.count - 1 else { return enumerator.element }
                var mutable = enumerator.element
                mutable.append(.pageBreak(id: UUID().uuidString, pageNumber: enumerator.offset))
                return mutable
            }
            .joined()
        return (items: finalArray, lastSectionOccupiedHeight: sectionedArray.last?.height ?? 0)
    }
    
    func split(occupiedHeight: CGFloat) -> [[ASNodeRow]] {
        var occupiedHeight = occupiedHeight
        return reduce([]) { (acc, row) -> [[ASNodeRow]] in
            var acc = acc
            guard !acc.isEmpty else { return [[row]] }
            if var lastArray = acc.last, lastArray.height + row.height < PageSize.A4.height - occupiedHeight || row.isPadder {
                lastArray.append(row)
                acc[acc.count - 1] = lastArray
                return acc
            }
            occupiedHeight = 0
            acc.append([row])
            return acc
        }
    }
}
