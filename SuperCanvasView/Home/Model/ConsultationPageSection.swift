//
//  ConsultationPageSection.swift
//  SuperCanvasView
//
//  Created by Krishna C Aluru on 10/6/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import RxDataSources

struct ConsultationPageSection {
    var items: [Item]
    var pageHeight: CGFloat
    var usedHeight: CGFloat {
        return items.filter { item in !item.medicalTerm.isPadder }.reduce(0, { result, item in result + item.height })
    }
    var needsNextPage: Bool {
        return pageHeight - usedHeight <= 70
    }
    var nextPage: ConsultationPageSection? {
        guard pageHeight - usedHeight <= 70, let lastItem = items.last else { return nil }
        switch lastItem.medicalTerm.medicalSection {
        case .symptoms: return ConsultationPageSection(items: [ConsultationRow(height: pageHeight, medicalTerm: MedicalTerm(name: nil, lines: [], medicalSection: .symptoms), maximumHeight: pageHeight)], pageHeight: pageHeight)
        case .diagnoses: return ConsultationPageSection(items: [ConsultationRow(height: pageHeight, medicalTerm: MedicalTerm(name: nil, lines: [], medicalSection: .diagnoses), maximumHeight: pageHeight)], pageHeight: pageHeight)
        }
    }
    var paddingRow: ConsultationRow? {
        guard pageHeight - usedHeight != 0 else { return nil }
        let heightToBePadded = pageHeight - usedHeight
        if let medicalSection = items.last?.medicalTerm.medicalSection {
            switch medicalSection {
            case .symptoms: return ConsultationRow(height: heightToBePadded, medicalTerm: MedicalTerm(name: nil, lines: [], medicalSection: .symptoms), maximumHeight: pageHeight)
            case .diagnoses: return ConsultationRow(height: heightToBePadded, medicalTerm: MedicalTerm(name: nil, lines: [], medicalSection: .diagnoses), maximumHeight: pageHeight)
            }
        }
        return ConsultationRow(height: heightToBePadded, medicalTerm: MedicalTerm(name: nil, lines: [], medicalSection: .symptoms), maximumHeight: pageHeight)
    }
    
    func canInsertRow(with height: CGFloat) -> Bool {
        return height <= pageHeight - usedHeight
    }
}

extension ConsultationPageSection: SectionModelType {
    typealias Item = ConsultationRow
    
    init(original: ConsultationPageSection, items: [Item]) {
        self = original
        self.items = items
    }
}
