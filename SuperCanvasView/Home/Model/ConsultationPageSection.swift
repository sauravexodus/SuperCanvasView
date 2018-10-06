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
        return items.filter { item in item.medicalSection != .none }.reduce(0, { result, item in result + item.height })
    }
    var isPageFull: Bool {
        return pageHeight == usedHeight
    }
    var heightToBePadded: Float {
        return pageHeight - usedHeight
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
