//
//  MedicalForm.swift
//  SuperCanvasView
//
//  Created by Krishna C Aluru on 10/19/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation

protocol MedicalFormType {
    var value: NSAttributedString? { get set }
    var hashValue: Int { get }
    
    init() // initialize as term with no content
}

// TODO: Would this work across sections?
func == (lhs: MedicalFormType, rhs: MedicalFormType) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

// MARK: Concrete Types

// TODO: Remove this when using Swift 4.2
extension MedicalFormType where Self: Hashable {
    var hashValue: Int {
        return value?.hashValue ?? 0
    }
}

struct ObstetricHistory: MedicalFormType, Hashable {
    var value: NSAttributedString?
}

struct MenstrualHistory: MedicalFormType, Hashable {
    var value: NSAttributedString?
}

struct FamilyHistory: MedicalFormType, Hashable {
    var value: NSAttributedString?
}

struct PersonalHistory: MedicalFormType, Hashable {
    var value: NSAttributedString?
}

struct GeneralHistory: MedicalFormType, Hashable {
    var value: NSAttributedString?
}
