//
//  ConsultationRow.swift
//  SuperCanvasView
//
//  Created by Krishna C Aluru on 10/6/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation

struct ConsultationRow {
    let id = UUID().uuidString
    let height: Float
    let lines: [Line]
    let medicalTerm: MedicalTermType
    var needsHeader: Bool
    var header: String? {
        guard needsHeader else { return nil }
        return medicalTerm.sectionOfSelf.displayTitle
    }
    
    var isPadder: Bool {
        return medicalTerm.name == nil && lines.isEmpty
    }
    init(height: Float, lines: [Line], medicalTerm: MedicalTermType, needsHeader: Bool = false) {
        self.height = height
        self.lines = lines
        self.medicalTerm = medicalTerm
        self.needsHeader = needsHeader
    }
}

extension ConsultationRow: Equatable { }

func ==(lhs: ConsultationRow, rhs: ConsultationRow) -> Bool {
    return lhs.id == rhs.id
}
