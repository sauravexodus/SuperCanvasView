//
//  MedicalTerm.swift
//  SuperCanvasView
//
//  Created by Krishna C Aluru on 10/6/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation

protocol MedicalTermType {
    static var section: MedicalSection { get }
    var name: String? { get }
    var hashValue: Int { get }
    
    init() // initialize as term with no content
}

extension MedicalTermType {
    var sectionOfSelf: MedicalSection {
        return type(of: self).section
    }
}

func == (lhs: MedicalTermType, rhs: MedicalTermType) -> Bool {
    guard type(of: lhs).section == type(of: rhs).section else {
        return false
    }
    return lhs.hashValue == rhs.hashValue
}

// MARK: Concrete Types

// TODO: Remove this when using Swift 4.2
extension MedicalTermType where Self: Hashable {
    var hashValue: Int {
        return name?.hashValue ?? 0
    }
}

struct Symptom: MedicalTermType, Hashable {
    static let section: MedicalSection = .symptoms
    var name: String?
}

struct Examination: MedicalTermType, Hashable {
    static let section: MedicalSection = .examinations
    var name: String?
}

struct Diagnosis: MedicalTermType, Hashable {
    static let section: MedicalSection = .diagnoses
    var name: String?
}

struct Prescription: MedicalTermType, Hashable {
    static let section: MedicalSection = .prescriptions
    var name: String?
}

struct Test: MedicalTermType, Hashable {
    static let section: MedicalSection = .tests
    var name: String?
}

struct Procedure: MedicalTermType, Hashable {
    static let section: MedicalSection = .procedures
    var name: String?
}

struct Instruction: MedicalTermType, Hashable {
    static let section: MedicalSection = .instructions
    var name: String?
}

struct NoMedicalTerm: MedicalTermType, Hashable {
    static let section: MedicalSection = .none
    var name: String?
}
