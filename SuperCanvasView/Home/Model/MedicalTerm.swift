//
//  MedicalTerm.swift
//  SuperCanvasView
//
//  Created by Krishna C Aluru on 10/6/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation

struct MedicalTerm {
    var name: String?
    var lines: [Line]
    var medicalSection: MedicalSection
    var isPadder: Bool {
        return name == nil && lines.isEmpty
    }
    
    enum MedicalSection {
        case symptoms
        case diagnoses
        
        var title: String {
            switch self {
            case .symptoms: return "Chief Complaints"
            case .diagnoses: return "Diagnosis"
            }
        }
        
        var displayTitle: String {
            return title
        }
    }
}

extension MedicalTerm: Equatable { }

func ==(lhs: MedicalTerm, rhs: MedicalTerm) -> Bool {
    return lhs.name == rhs.name && lhs.lines == rhs.lines && lhs.medicalSection == rhs.medicalSection
}
