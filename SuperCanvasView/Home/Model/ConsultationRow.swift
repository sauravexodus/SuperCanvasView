//
//  ConsultationRow.swift
//  SuperCanvasView
//
//  Created by Krishna C Aluru on 10/6/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import UIKit

struct ConsultationRow {
    let id = UUID().uuidString
    var height: CGFloat
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
    init(height: CGFloat, lines: [Line], medicalTerm: MedicalTermType, needsHeader: Bool = false) {
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
