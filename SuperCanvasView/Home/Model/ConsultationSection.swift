//
//  ConsultationSection.swift
//  SuperCanvasView
//
//  Created by Krishna C Aluru on 10/6/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import RxDataSources

struct ConsultationSection {
    var medicalSection: MedicalSection
    var items: [Item]
    
    init(medicalSection: MedicalSection, items: [Item]) {
        self.medicalSection = medicalSection
        self.items = items
    }
    
    mutating func insert(_ nodeRow: ASNodeRow, with terminalCellHeight: CGFloat) {
        guard case let .medicalTerm(_,_,_,medicalTerm) = nodeRow else { return }
        let padderRow = ASNodeRow(height: terminalCellHeight, lines: [], medicalTerm: medicalTerm.sectionOfSelf.correspondingEmptyTerm)
        if let lastItem = items.last, lastItem.isPadder {
            items.removeLast()
        }
        items += [nodeRow, padderRow]
    }
    
    mutating func addTerminalCell(with height: CGFloat) {
        if let lastItem = items.last, !lastItem.isPadder, case let .medicalTerm(_, _, _, medicalTerm) = lastItem {
            items.append(ASNodeRow(height: height, lines: [], medicalTerm: medicalTerm.sectionOfSelf.correspondingEmptyTerm))
        }
    }
}

extension ConsultationSection: AnimatableSectionModelType {
    typealias Item = ASNodeRow
    typealias Identity = MedicalSection
    
    var identity: MedicalSection {
        return medicalSection
    }
    
    init(original: ConsultationSection, items: [Item]) {
        self = original
        self.items = items
    }
}

extension Array where Element == ConsultationSection {
    func withPageBreaks() -> [ConsultationSection] {
        var lastRemainingSpace: CGFloat = 0
        return map {
            var mutable = $0
            mutable.items = $0.items.withPageBreaks(occupiedHeight: lastRemainingSpace)
            lastRemainingSpace = mutable.items.remaningHeight(occupiedHeight: lastRemainingSpace)
            return mutable
        }
    }
    
    func removingPageBreaks() -> [ConsultationSection] {
        return map {
            var mutable = $0
            mutable.items = $0.items.filter {
                guard case .pageBreak = $0 else { return true }
                return false
            }
            return mutable
        }
    }
}
