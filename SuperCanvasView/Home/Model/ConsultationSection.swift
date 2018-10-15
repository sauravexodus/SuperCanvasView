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
    
    var isEmpty: Bool {
        return items.count == 0 || (items.count == 1 && items[0].isTerminal)
    }
    
    init(medicalSection: MedicalSection, items: [Item]) {
        self.medicalSection = medicalSection
        self.items = items
    }
    
    mutating func insert(_ consultationRow: ConsultationRow, with terminalCellHeight: CGFloat) {
        guard case let .medicalTerm(_,_,_,medicalTerm) = consultationRow else { return }
        let padderRow = ConsultationRow(height: terminalCellHeight, lines: [], medicalTerm: medicalTerm.sectionOfSelf.correspondingEmptyTerm)
        if let lastItem = items.last, lastItem.isTerminal {
            items.removeLast()
        }
        items += [consultationRow, padderRow]
    }
    
    mutating func addTerminalCell(with height: CGFloat) {
        if items.count == 0 {
            items.append(ConsultationRow(height: height, lines: [], medicalTerm: medicalSection.correspondingEmptyTerm))
        }
        if let lastItem = items.last, !lastItem.isTerminal, case let .medicalTerm(_, _, _, medicalTerm) = lastItem {
            items.append(ConsultationRow(height: height, lines: [], medicalTerm: medicalTerm.sectionOfSelf.correspondingEmptyTerm))
        }
    }
}

extension ConsultationSection: AnimatableSectionModelType {
    typealias Item = ConsultationRow
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
        var occupiedHeight: CGFloat = 0
        return map {
            var mutable = $0
            print("[Page Break] Section Changed \($0.medicalSection.title)")
            (mutable.items, occupiedHeight) = $0.items.withPageBreaks(occupiedHeight: occupiedHeight + 16)
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
