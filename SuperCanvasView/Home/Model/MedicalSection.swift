//
//  MedicalSection.swift
//  SuperCanvasView
//
//  Created by Vatsal Manot on 10/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation

typealias MedicalSection = Either<MedicalTermSection, MedicalFormSection>

enum Either<T, U> {
    case left(T)
    case right(U)
    
    var leftValue: T? {
        if case let .left(value) = self {
            return value
        }
        return nil
    }
    var rightValue: U? {
        if case let .right(value) = self {
            return value
        }
        return nil
    }
}

extension Either where T == MedicalTermSection, U == MedicalFormSection {
    var printPosition: Int {
        switch self {
        case let .left(value):
            return MedicalTermSection.allSections().firstIndex(of: value) ?? 0
        case let .right(value):
            return MedicalFormSection.allSections().firstIndex(of: value) ?? 0
        }
    }
    
    static func allSections() -> [MedicalSection] {
        return MedicalTermSection.allSections().map(Either.left) + MedicalFormSection.allSections().map(Either.right)
    }
    
    var isMedicalTermSection: Bool {
        guard case .left = self else { return false }
        return true
    }
    
    var isMedicalFormSection: Bool {
        return !isMedicalTermSection
    }
    
    var displayTitle: String {
        switch self {
        case .left: return leftValue!.displayTitle
        case .right: return rightValue!.displayTitle
        }
    }
    
    var shortDisplayTitle: String {
        switch self {
        case .left: return leftValue!.shortDisplayTitle
        case .right: return rightValue!.shortDisplayTitle
        }
    }
}

extension Either where T: Equatable {
    static func == (lhs: Either, rhs: T) -> Bool {
        switch lhs {
        case let .left(value):
            return value == rhs
        default:
            return false
        }
    }
}

extension Either where U: Equatable {
    static func == (lhs: Either, rhs: U) -> Bool {
        switch lhs {
        case let .right(value):
            return value == rhs
        default:
            return false
        }
    }
}

enum MedicalFormSection: Int, Hashable {
    case menstrualHistory
    case obstetricHistory
    case familyHistory
    case personalHistory
    case generalHistory
    
    var title: String {
        switch self {
        case .menstrualHistory: return "Menstrual History"
        case .obstetricHistory: return "Obstetric History"
        case .familyHistory: return "Family History"
        case .personalHistory: return "Personal History"
        case .generalHistory: return "General History"
        }
    }
    
    var displayTitle: String {
        return title
    }
    
    var shortDisplayTitle: String {
        switch self {
        case .menstrualHistory: return "Menstrual"
        case .obstetricHistory: return "Obstetric"
        case .familyHistory: return "Family"
        case .personalHistory: return "Personal"
        case .generalHistory: return "General"
        }
    }
    
    static func allSections() -> [MedicalFormSection] {
        return [.menstrualHistory]
    }
}

enum MedicalTermSection: Int, Hashable {
    case symptoms
    case examinations
    case diagnoses
    case prescriptions
    case tests
    case procedures
    case instructions
    case none
    
    var printPosition: Int {
        return MedicalTermSection.allSections().firstIndex(of: self) ?? 0
    }
    
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
    
    var shortDisplayTitle: String {
        switch self {
        case .symptoms: return "Complaints"
        case .examinations: return "Examinations"
        case .diagnoses: return "Diagnosis"
        case .prescriptions: return "Prescription"
        case .tests: return "Investigations"
        case .procedures: return "Procedures"
        case .instructions: return "Instructions"
        case .none: return ""
        }
    }
    
    static func allSections() -> [MedicalTermSection] {
        return [.symptoms, .diagnoses]
    }
}
