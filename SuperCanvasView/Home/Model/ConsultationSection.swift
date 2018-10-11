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
    
    mutating func insert(_ consultationRow: ConsultationRow, with minimumHeight: CGFloat) {
        let padderRow = ConsultationRow(height: minimumHeight, lines: [], medicalTerm: consultationRow.medicalTerm.sectionOfSelf.correspondingEmptyTerm)
        if let lastItem = items.last, lastItem.isPadder {
            items.removeLast()
        }
        items += [consultationRow, padderRow]
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
