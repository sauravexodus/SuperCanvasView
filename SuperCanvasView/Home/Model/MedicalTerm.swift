//
//  MedicalTerm.swift
//  SuperCanvasView
//
//  Created by Krishna C Aluru on 10/6/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation

protocol MedicalTermType {
    var name: String? { get set }
    var hashValue: Int { get }
    
    init() // initialize as term with no content
}

// TODO: Would this work across sections?
func == (lhs: MedicalTermType, rhs: MedicalTermType) -> Bool {
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
    var name: String?
}

struct Examination: MedicalTermType, Hashable {
    var name: String?
}

struct Diagnosis: MedicalTermType, Hashable {
    var name: String?
}

struct Prescription: MedicalTermType, Hashable {
    var name: String?
}

struct Test: MedicalTermType, Hashable {
    var name: String?
}

struct Procedure: MedicalTermType, Hashable {
    var name: String?
}

struct Instruction: MedicalTermType, Hashable {
    var name: String?
}
