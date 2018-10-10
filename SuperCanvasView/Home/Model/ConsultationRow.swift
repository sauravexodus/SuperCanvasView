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
    let maximumHeight: CGFloat
    let medicalTerm: MedicalTerm
    var needsHeader: Bool
    var header: String? {
        guard needsHeader else { return nil }
        return medicalTerm.medicalSection.displayTitle
    }
    
    init(height: CGFloat, medicalTerm: MedicalTerm, maximumHeight: CGFloat, needsHeader: Bool = false) {
        self.height = height
        self.medicalTerm = medicalTerm
        self.maximumHeight = maximumHeight
        self.needsHeader = needsHeader
    }
}

extension ConsultationRow: Equatable { }

func ==(lhs: ConsultationRow, rhs: ConsultationRow) -> Bool {
    return lhs.id == rhs.id
}
