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
    var medicalTerm: MedicalTermType
    var needsHeader: Bool
    var header: String? {
        guard needsHeader else { return nil }
        return medicalTerm.sectionOfSelf.displayTitle
    }
    
    var isPadder: Bool {
        return medicalTerm.name == nil && lines.isEmpty
    }
    init(height: CGFloat?, lines: [Line], medicalTerm: MedicalTermType, needsHeader: Bool = false) {
        self.height = height ?? 0
        self.lines = lines
        self.medicalTerm = medicalTerm
        self.needsHeader = needsHeader
        
        if height == nil {
           self.height = intrinsicContentHeight
        }
    }
}

extension ConsultationRow {
    var heightWithHeader: CGFloat {
        return height + (needsHeader ? 20 : 0)
    }
    
    var intrinsicContentHeight: CGFloat {
        let string = NSAttributedString(string: medicalTerm.name ?? "", attributes: [.font: UIFont.preferredPrintFont(forTextStyle: .body)])
        let stringHeight = string.height(withConstrainedWidth: PDFPageSize.A4.width)
        
        return stringHeight + (appropriateInset * 2)
    }
    
    var appropriateInset: CGFloat {
        switch PrintFontSetting.current {
        case .compact:
            return 8
        case .regular:
            return 16
        case .comfortable:
            return 24
        }
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

extension NSAttributedString {
    func height(withConstrainedWidth width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstrainedHeight height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        
        return ceil(boundingBox.width)
    }
}
