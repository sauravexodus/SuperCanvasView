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
    var lines: [Line]
    let medicalTerm: MedicalTermType
    
    var isTerminal: Bool {
        return medicalTerm.name == nil && lines.isEmpty
    }
    
    var contentHeight: CGFloat {
        return min(CGFloat(max(CGFloat(height), lines.highestY ?? 0)), 842)
    }
    var isPageBreak: Bool
    
    init(height: CGFloat, lines: [Line], medicalTerm: MedicalTermType, isPageBreak: Bool = false) {
        self.height = height
        self.lines = lines
        self.medicalTerm = medicalTerm
        self.isPageBreak = isPageBreak
    }
}

extension ConsultationRow: Hashable {
    static func == (lhs: ConsultationRow, rhs: ConsultationRow) -> Bool {
        return lhs.id == rhs.id
    }
    
    var hashValue: Int {
        return id.hashValue
    }
}
