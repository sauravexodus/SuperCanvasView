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
    var pageIndex: Int
    
    init(items: [Item], pageHeight: CGFloat, pageIndex: Int) {
        self.items = items
        self.pageHeight = pageHeight
        self.pageIndex = pageIndex
    }
    
    var usedHeight: CGFloat {
        return items.filter { item in !item.isPadder }.reduce(0, { result, item in result + item.height })
    }
    
    var needsNextPage: Bool {
        return pageHeight - usedHeight <= 70
    }
    
    var nextPage: ConsultationPageSection? {
        guard pageHeight - usedHeight <= 70, let lastItem = items.last else { return nil }
        return ConsultationPageSection(items: [ConsultationRow(height: pageHeight, lines: [], medicalTerm: lastItem.medicalTerm.sectionOfSelf.correspondingEmptyTerm)], pageHeight: pageHeight, pageIndex: pageIndex + 1)
    }
    
    var paddingRow: ConsultationRow? {
        guard pageHeight - usedHeight != 0 else { return nil }
        let heightToBePadded = pageHeight - usedHeight
        if let medicalSection = items.last?.medicalTerm.sectionOfSelf {
            return ConsultationRow(height: heightToBePadded, lines: [], medicalTerm: medicalSection.correspondingEmptyTerm)
        }
        return ConsultationRow(height: heightToBePadded, lines: [], medicalTerm: NoMedicalTerm(name: nil))
    }
    
    func canInsertRow(with height: CGFloat) -> Bool {
        return height <= pageHeight - usedHeight
    }
}

extension ConsultationPageSection: AnimatableSectionModelType {
    typealias Item = ConsultationRow
    typealias Identity = Int
    
    var identity: Int {
        return pageIndex
    }
    
    init(original: ConsultationPageSection, items: [Item]) {
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
