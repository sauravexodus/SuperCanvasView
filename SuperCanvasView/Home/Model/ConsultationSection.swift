//
//  ConsultationSection.swift
//  SuperCanvasView
//
//  Created by Krishna C Aluru on 10/6/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import RxDataSources

struct ConsultationSection {
    var medicalSection: MedicalSection
    var items: [Item]
    
    var isEmpty: Bool {
        return items.count == 0 || (items.count == 1 && items[0].isTerminal)
    }
    
    init(medicalSection: MedicalSection, items: [Item]) {
        self.medicalSection = medicalSection
        self.items = items
    }
    
    mutating func insert(_ consultationRow: ConsultationRow) {
        guard case .medicalTerm = consultationRow, let termSection = medicalSection.medicalTermSectionValue else { return }
        let padderRow = ConsultationRow(lines: [], medicalTermSection: termSection)
        if let lastItem = items.last, lastItem.isTerminal {
            items.removeLast()
        }
        items += [consultationRow, padderRow]
    }
    
    mutating func addTerminalCell() {
        guard let termSection = medicalSection.medicalTermSectionValue else { return }
        if items.count == 0 {
            items.append(ConsultationRow(lines: [], medicalTermSection: termSection))
        }
        if let lastItem = items.last, !lastItem.isTerminal, case .medicalTerm = lastItem {
            items.append(ConsultationRow(lines: [], medicalTermSection: termSection))
        }
    }
}

extension ConsultationSection: AnimatableSectionModelType {
    typealias Item = ConsultationRow
    typealias Identity = MedicalSection
    
    var identity: MedicalSection {
        return medicalSection
    }
    
    init(original: ConsultationSection, items: [Item]) {
        self = original
        self.items = items
    }
}

extension Array where Element == ConsultationSection {
    func withPageBreaks(sectionHeaderHeight: CGFloat) -> [ConsultationSection] {
        var currentHeight: CGFloat = 0
        var pageNumber = 0
        return map {
            var mutable = $0
            var items: [ConsultationRow] = []
            currentHeight += 16
            $0.items.forEach { row in
                if row.isTerminal {
                    items.append(row)
                    return
                }
                if currentHeight + row.height > PageSize.selectedPage.height {
                    items.append(.pageBreak(pageNumber: pageNumber))
                    pageNumber += 1
                    currentHeight = 0
                }
                items.append(row)
                currentHeight += row.height
            }
            if currentHeight + sectionHeaderHeight > PageSize.selectedPage.height {
                items.append(.pageBreak(pageNumber: pageNumber))
                pageNumber += 1
                currentHeight = 0
            }
            mutable.items = items
            return mutable
        }
    }
    
    func removingPageBreaks() -> [ConsultationSection] {
        return map {
            var mutable = $0
            mutable.items = $0.items.filter {
                guard case .pageBreak = $0 else { return true }
                return false
            }
            return mutable
        }
    }
}
