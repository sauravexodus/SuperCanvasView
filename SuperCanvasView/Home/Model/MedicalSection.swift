//
//  MedicalSection.swift
//  SuperCanvasView
//
//  Created by Vatsal Manot on 10/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import RxDataSources
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
    
    init(_ left: T) {
        self = .left(left)
    }
    
    init(_ right: U) {
        self = .right(right)
    }
}

extension Either: Equatable where T: Equatable, U: Equatable {
    static func == (lhs: Either, rhs: Either) -> Bool {
        switch (lhs, rhs) {
        case let (.left(x), .left(y)):
            return x == y
        case let (.right(x), .right(y)):
            return x == y
        default:
            return false
        }
    }
}

extension Either: Hashable where T: Hashable, U: Hashable {
    var hashValue: Int {
        switch self {
        case let .left(x):
            return combineHashes([ObjectIdentifier(T.self).hashValue, x.hashValue])
        case let .right(y):
            return combineHashes([ObjectIdentifier(U.self).hashValue, y.hashValue])
        }
    }
}

extension Either: IdentifiableType where T == MedicalTermSection, U == MedicalFormSection {
    typealias Identity = Int

    var identity: Int {
        return hashValue
    }

    var title: String {
        switch self {
        case .left: return leftValue!.title
        case .right: return rightValue!.title
        }
    }

    var printPosition: Int {
        switch self {
        case let .left(value):
            return MedicalTermSection.allSections().firstIndex(of: value) ?? 0
        case let .right(value):
            return MedicalFormSection.allSections().firstIndex(of: value) ?? 0
        }
    }
    
    // TODO: should be ordererd by print position!
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
    
    var medicalTermSectionValue: MedicalTermSection? {
        return leftValue
    }
    var medicalFormSectionValue: MedicalFormSection? {
        return rightValue
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
    
    var title: String {
        switch self {
        case .symptoms: return "Chief Complaints"
        case .examinations: return "Examinations"
        case .diagnoses: return "Diagnosis"
        case .prescriptions: return "Prescription"
        case .tests: return "Investigations"
        case .procedures: return "Procedures"
        case .instructions: return "Instructions"
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
        }
    }
    
    static func allSections() -> [MedicalTermSection] {
        return [.symptoms, .diagnoses]
    }
}
