//
//  MedicalSection.swift
//  SuperCanvasView
//
//  Created by Krishna C Aluru on 10/6/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation

enum MedicalSection {
    case symptoms(name: String?, lines: [Line])
    case diagnoses(name: String?, lines: [Line])
    
    var isPadder: Bool {
        switch self {
        case let .symptoms(name, lines):
            return name == nil && lines.isEmpty
        case let .diagnoses(name, lines):
            return name == nil && lines.isEmpty
        }
    }
}

extension MedicalSection: Equatable { }

func ==(lhs: MedicalSection, rhs: MedicalSection) -> Bool {
    switch (lhs, rhs) {
    case (let .symptoms(nameA, linesA), let .symptoms(nameB, linesB)):
        return nameA == nameB && linesA == linesB
    case (let .diagnoses(nameA, linesA), let .diagnoses(nameB, linesB)):
        return nameA == nameB && linesA == linesB
    default: return false
    }
}
