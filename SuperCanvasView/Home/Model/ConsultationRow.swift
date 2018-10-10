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
    let medicalTerm: MedicalTerm
    var needsHeader: Bool
    var header: String? {
        guard needsHeader else { return nil }
        return medicalTerm.medicalSection.displayTitle
    }
    
    init(height: Float, medicalTerm: MedicalTerm, needsHeader: Bool = false) {
        self.height = height
        self.medicalTerm = medicalTerm
        self.needsHeader = needsHeader
    }
}

extension ConsultationRow: Equatable {
    static func == (lhs: ConsultationRow, rhs: ConsultationRow) -> Bool {
        return lhs.id == rhs.id
    }
}
