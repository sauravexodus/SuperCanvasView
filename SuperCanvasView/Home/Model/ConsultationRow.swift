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
    case medicalTerm(id: String, lines: [Line], medicalTermSection: MedicalTermSection, medicalTermType: MedicalTermType?)
    case medicalForm(id: String, lines: [Line], medicalFormSection: MedicalFormSection, medicalFormType: MedicalFormType?)
    case pageBreak(pageNumber: Int)
    
    init(lines: [Line], medicalTermSection: MedicalTermSection, medicalTerm: MedicalTermType? = nil) {
        self = .medicalTerm(id: UUID().uuidString, lines: lines, medicalTermSection: medicalTermSection, medicalTermType: medicalTerm)
    }
    
    init(lines: [Line], medicalFormSection: MedicalFormSection, medicalForm: MedicalFormType? = nil) {
        self = .medicalForm(id: UUID().uuidString, lines: lines, medicalFormSection: medicalFormSection, medicalFormType: medicalForm)
    }
    
    var isTerminal: Bool {
        switch self {
        case let .medicalTerm(_, lines, _, medicalTerm): return medicalTerm == nil && lines.isEmpty
        case let .medicalForm(_, lines, _, medicalForm): return medicalForm == nil && lines.isEmpty
        case .pageBreak: return false
        }
    }
    
    var isPageBreak: Bool {
        switch self {
        case .pageBreak: return true
        default: return false
        }
    }
    
    var medicalTerm: MedicalTermType? {
        switch self {
        case let .medicalTerm(_, _, _, medicalTerm): return medicalTerm
        default: return nil
        }
    }
    
    var medicalTermSection: MedicalTermSection? {
        switch self {
        case let .medicalTerm(_, _, section, _): return section
        default: return nil
        }
    }
    
    var medicalForm: MedicalFormType? {
        switch self {
        case let .medicalForm(_, _, _, medicalForm): return medicalForm
        default: return nil
        }
    }
    
    var medicalFormSection: MedicalFormSection? {
        switch self {
        case let .medicalForm(_, _, section, _): return section
        default: return nil
        }
    }
    
    var lines: [Line] {
        get {
            switch self {
            case let .medicalTerm(_, lines, _, _): return lines
            case let .medicalForm(_, lines, _, _): return lines
            case .pageBreak: fatalError("This is a page break row type!")
            }
        }
        set {
            switch self {
            case let .medicalTerm(id, _, section, medicalTerm):
                self = .medicalTerm(id: id, lines: newValue, medicalTermSection: section, medicalTermType: medicalTerm)
            case let .medicalForm(id, _, section, medicalForm):
                self = .medicalForm(id: id, lines: newValue, medicalFormSection: section, medicalFormType: medicalForm)
            case .pageBreak:
                fatalError("This is a page break row type!")
            }
        }
    }
    
    var height: CGFloat {
        switch self {
        case let .medicalTerm(_, lines, _, _):
            return isTerminal ? ConsultationRow.terminalHeight : min(max(textHeight, lines.highestY ?? 0), ConsultationRow.maximumHeight)
        case let .medicalForm(_, lines, _, _):
            return isTerminal ? ConsultationRow.terminalHeight : min(max(textHeight, lines.highestY ?? 0), ConsultationRow.maximumHeight)
        case .pageBreak: return 1
        }
    }
    
    func getHeightExpansionProperties(with height: CGFloat) -> (needsToExpand: Bool, expandedHeight: CGFloat) {
        return (needsToExpand: height + 30 < ConsultationRow.maximumHeight, expandedHeight: height + 30)
    }
    
    static let terminalHeight: CGFloat = 40
    
    static let maximumHeight: CGFloat = PageSize.selectedPage.height
    
    var textHeight: CGFloat {
        switch self {
        case let .medicalTerm(_, _, _, medicalTerm):
            return NSAttributedString(string: medicalTerm?.name ?? "", attributes: [.font: FontSpecification.medicalTermText]).heightConstrainedToPageWidth + 4 // for bottom inset on cell
        case let .medicalForm(_, _, _, medicalForm):
            return (medicalForm?.value ?? NSAttributedString(string: "", attributes: [.font: FontSpecification.medicalTermText])).heightConstrainedToPageWidth + 4 // for bottom inset on cell
        case .pageBreak: fatalError("page break doesn't have text height!")
        }
    }
    
    var id: String {
        switch self {
        case let .medicalTerm(id, _, _, _): return id
        case let .medicalForm(id, _, _, _): return id
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
