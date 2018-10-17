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

enum ConsultationRow {
    case medicalTerm(id: String, height: CGFloat, lines: [Line], medicalTermType: MedicalTermType)
    case pageBreak(pageNumber: Int)
    
    init(height: CGFloat, lines: [Line], medicalTerm: MedicalTermType) {
        self = .medicalTerm(id: UUID().uuidString, height: height, lines: lines, medicalTermType: medicalTerm)
    }
    
    var isTerminal: Bool {
        switch self {
        case let .medicalTerm(_, _, lines, medicalTerm): return medicalTerm.name == nil && lines.isEmpty
        default: return false
        }
    }
    
    var isPageBreak: Bool {
        switch self {
        case .pageBreak: return true
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
        case let .pageBreak(pageNumber): return "\(pageNumber)"
        }
    }
}

extension ConsultationRow: Hashable {
    static func == (lhs: ConsultationRow, rhs: ConsultationRow) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    var hashValue: Int {
        return id.hashValue
    }
}

extension ConsultationRow: IdentifiableType {
    typealias Identity = String
    
    var identity: String {
        return id
    }
}
