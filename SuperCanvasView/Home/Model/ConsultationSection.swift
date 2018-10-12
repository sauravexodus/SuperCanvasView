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
    
    var isEmpty: Bool {
        return items.count == 0 || (items.count == 1 && items[0].isTerminal)
    }
    
    mutating func insert(_ consultationRow: ConsultationRow, with terminalCellHeight: CGFloat) {
        let padderRow = ConsultationRow(height: terminalCellHeight, lines: [], medicalTerm: medicalSection.correspondingEmptyTerm)
        if let lastItem = items.last, lastItem.isTerminal {
            items.removeLast()
        }
        items += [consultationRow, padderRow]
    }
    
    mutating func addTerminalCell(with height: CGFloat) {
        if items.count == 0 {
            items.append(ConsultationRow(height: height, lines: [], medicalTerm: medicalSection.correspondingEmptyTerm))
        }
        if let lastItem = items.last, !lastItem.isTerminal {
            items.append(ConsultationRow(height: height, lines: [], medicalTerm: medicalSection.correspondingEmptyTerm))
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

extension ConsultationRow: IdentifiableType {
    typealias Identity = String
    
    var identity: String {
        return id
    }
}
