//
//  MedicalSection.swift
//  SuperCanvasView
//
//  Created by Vatsal Manot on 10/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation

enum MedicalSection: Int, Hashable {
    case symptoms
    case examinations
    case diagnoses
    case prescriptions
    case tests
    case procedures
    case instructions
    case none
    
    var title: String {
        switch self {
        case .symptoms: return "Chief Complaints"
        case .examinations: return "Examinations"
        case .diagnoses: return "Diagnosis"
        case .prescriptions: return "Prescription"
        case .tests: return "Investigations"
        case .procedures: return "Procedures"
        case .instructions: return "Instructions"
        case .none: return ""
        }
    }
    
    var displayTitle: String {
        return title
    }
}

extension MedicalSection {
    var correspondingMedicalTermType: MedicalTermType.Type {
        switch self {
        case .symptoms:
            return Symptom.self
        case .examinations:
            return Examination.self
        case .diagnoses:
            return Diagnosis.self
        case .prescriptions:
            return Prescription.self
        case .tests:
            return Test.self
        case .procedures:
            return Procedure.self
        case .instructions:
            return Instruction.self
        case .none:
            return NoMedicalTerm.self
        }
    }
    var correspondingEmptyTerm: MedicalTermType {
        return correspondingMedicalTermType.init()
    }
}
