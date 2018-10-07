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
    var pageHeight: Float
    var usedHeight: Float {
        return items.filter { item in !item.medicalSection.isPadder }.reduce(0, { result, item in result + item.height })
    }
    var needsNextPage: Bool {
        return pageHeight - usedHeight <= 70
    }
    var nextPage: ConsultationPageSection? {
        guard pageHeight - usedHeight <= 70, let lastItem = items.last else { return nil }
        switch lastItem.medicalSection {
        case .symptoms: return ConsultationPageSection(items: [ConsultationRow(height: pageHeight, medicalSection: .symptoms(name: nil, lines: []))], pageHeight: pageHeight)
        case .diagnoses: return ConsultationPageSection(items: [ConsultationRow(height: pageHeight, medicalSection: .diagnoses(name: nil, lines: []))], pageHeight: pageHeight)
        }
    }
    var paddingRow: ConsultationRow? {
        guard pageHeight - usedHeight != 0 else { return nil }
        let heightToBePadded = pageHeight - usedHeight
        if let medicalSection = items.last?.medicalSection {
            switch medicalSection {
            case .symptoms: return ConsultationRow(height: heightToBePadded, medicalSection: .symptoms(name: nil, lines: []))
            case .diagnoses: return ConsultationRow(height: heightToBePadded, medicalSection: .diagnoses(name: nil, lines: []))
            }
        }
        return ConsultationRow(height: heightToBePadded, medicalSection: .symptoms(name: nil, lines: []))
    }
    
    func canInsertRow(with height: Float) -> Bool {
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
