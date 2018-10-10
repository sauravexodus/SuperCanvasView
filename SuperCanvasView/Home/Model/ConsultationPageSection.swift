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
        return items.filter { item in !item.isPadder }.reduce(0, { result, item in result + item.height })
    }
    
    var needsNextPage: Bool {
        return pageHeight - usedHeight <= 70
    }
    
    var nextPage: ConsultationPageSection? {
        guard pageHeight - usedHeight <= 70, let lastItem = items.last else {
            return nil
        }
        
        return ConsultationPageSection(items: [ConsultationRow(height: pageHeight, medicalTerm: lastItem.medicalTerm.sectionOfSelf.correspondingEmptyTerm)], pageHeight: pageHeight)
    }
    
    var paddingRow: ConsultationRow? {
        guard pageHeight - usedHeight != 0 else { return nil }
        let heightToBePadded = pageHeight - usedHeight
        if let medicalSection = items.last?.medicalTerm.sectionOfSelf {
            return ConsultationRow(height: heightToBePadded, medicalTerm: medicalSection.correspondingEmptyTerm)
        }
        return ConsultationRow(height: heightToBePadded, medicalTerm: NoMedicalTerm(name: nil))
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
