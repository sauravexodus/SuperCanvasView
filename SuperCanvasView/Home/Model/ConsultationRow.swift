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
    var height: Float
    var medicalTerm: MedicalTerm
}

extension ConsultationRow: Equatable { }

func ==(lhs: ConsultationRow, rhs: ConsultationRow) -> Bool {
    return lhs.id == rhs.id
}
