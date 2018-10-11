//
//  HomeViewModel.swift
//  SuperCanvasView
//
//  Created by Krishna C Aluru on 10/6/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import RxDataSources
import ReactorKit
import RxSwift

final class HomeViewModel: Reactor {
    typealias IndexPathWithScrollPosition = (indexPath: IndexPath, scrollPosition: UITableViewScrollPosition)
    typealias IndexPathWithHeight = (indexPath: IndexPath, height: CGFloat)

    enum Action {
        case initialLoad
        case updateLines(indexPath: IndexPath, lines: [Line])
        case select(MedicalSection)
        case add(MedicalTermType)
        case deleteAll
        case print([UIImage])
    }
    
    enum Mutation {
        case setSections([ConsultationSection])
        case setFocusedIndexPath(IndexPathWithScrollPosition)
    }
    
    struct State {
        var sections: [ConsultationSection] = []
        let pageHeight: CGFloat = 900
        let minimumHeight: CGFloat = 100
        var focusedIndexPath: IndexPathWithScrollPosition?
    }
    
    let initialState = State()
    
    func mutate(action: HomeViewModel.Action) -> Observable<HomeViewModel.Mutation> {
        switch action {
        case .initialLoad: return mutateInitialLoad()
        case let .select(medicalSection): return mutateSelectMedicalSection(medicalSection)
        case let .add(medicalTerm): return mutateAppendMedicalTerm(medicalTerm)
        case .deleteAll: return mutateInitialLoad()
        case let .updateLines(indexPath, lines): return mutateUpdatingLines(at: indexPath, lines: lines)
        case let .print(images): return mutatePrint(images: images)
        }
    }
    
    func reduce(state: HomeViewModel.State, mutation: HomeViewModel.Mutation) -> HomeViewModel.State {
        var state = state
        switch mutation {
        case let .setSections(sections):
            state.sections = sections
        case let .setFocusedIndexPath(indexPath):
            state.focusedIndexPath = indexPath
        }
        return state
    }
}

// MARK: Mutations

extension HomeViewModel {
    private func mutateInitialLoad() -> Observable<Mutation> {
        let medicalSection = MedicalSection.allSections()[0]
        return .just(.setSections([ConsultationSection(medicalSection: medicalSection, items: [ConsultationRow(height: currentState.pageHeight, lines: [Line](), medicalTerm: medicalSection.correspondingEmptyTerm)])]))
    }
    
    private func mutateSelectMedicalSection(_ medicalSection: MedicalSection) -> Observable<Mutation> {
        var sections = currentState.sections
        guard !sections.isEmpty, sections[0].items.count > 0, !sections[0].items[0].isPadder else {
            let consultationRow = ConsultationRow(height: currentState.pageHeight, lines: [], medicalTerm: medicalSection.correspondingEmptyTerm)
            return .just(.setSections([ConsultationSection(medicalSection: medicalSection, items: [consultationRow])]))
        }
        guard let sectionIndex = sections.firstIndex(where: { section in section.medicalSection == medicalSection }) else {
            let sectionIndex = sections.firstIndex(where: { section in section.medicalSection.printPosition > medicalSection.printPosition }) ?? sections.endIndex
            let consultationRow = ConsultationRow(height: currentState.minimumHeight, lines: [], medicalTerm: medicalSection.correspondingEmptyTerm)
            sections.insert(ConsultationSection(medicalSection: medicalSection, items: [consultationRow]), at: sectionIndex)
            let focusedIndexPath = IndexPathWithScrollPosition(indexPath: IndexPath(row: 0, section: sectionIndex), scrollPosition: .top)
            return .concat(.just(.setSections(sections)), .just(.setFocusedIndexPath(focusedIndexPath)))
        }
        let focusedIndexPath = IndexPathWithScrollPosition(indexPath: IndexPath(row: 0, section: sectionIndex), scrollPosition: .top)
        return .just(.setFocusedIndexPath(focusedIndexPath))
    }
    
    private func mutateAppendMedicalTerm(_ medicalTerm: MedicalTermType) -> Observable<Mutation> {
        var sections = currentState.sections
        let consultationRow = ConsultationRow(height: 62.5, lines: [], medicalTerm: medicalTerm)
        guard !sections.isEmpty else { return .just(.setSections([ConsultationSection(medicalSection: medicalTerm.sectionOfSelf, items: [consultationRow])])) }
        guard let sectionIndex = sections.firstIndex(where: { section in section.medicalSection == medicalTerm.sectionOfSelf }) else {
            let sectionIndex = sections.firstIndex(where: { section in section.medicalSection.printPosition > medicalTerm.sectionOfSelf.printPosition }) ?? sections.endIndex
            sections.insert(ConsultationSection(medicalSection: medicalTerm.sectionOfSelf, items: [consultationRow]), at: sectionIndex)
            return .just(.setSections(sections))
        }
        sections[sectionIndex].insert(consultationRow, with: currentState.minimumHeight)
        let rowIndex = sections[sectionIndex].items.count - 1
        let focusedIndexPath = IndexPathWithScrollPosition(indexPath: IndexPath(row: rowIndex, section: sectionIndex), scrollPosition: .none)
        return .concat(.just(.setSections(sections)), .just(.setFocusedIndexPath(focusedIndexPath)))
    }

    private func mutateUpdatingLines(at indexPath: IndexPath, lines: [Line]) -> Observable<Mutation> {
        var sections = currentState.sections
        guard sections.count > indexPath.section, sections[indexPath.section].items.count > indexPath.row else { return .empty() }
        sections[indexPath.section].items[indexPath.row].lines = lines
        return .just(.setSections(sections))
    }
    
    private func mutatePrint(images: [UIImage]) -> Observable<Mutation> {
        let pi = UIPrintInfo(dictionary: nil)
        pi.outputType = .general
        pi.jobName = "JOB"
        pi.orientation = .portrait
        pi.duplex = .longEdge
        let pic = UIPrintInteractionController.shared
        pic.printInfo = pi
        pic.printingItems = images
        pic.present(animated: true)
        return .empty()
    }
}

// MARK: Debugging

#if DEBUG
extension HomeViewModel {
    func transform(state: Observable<HomeViewModel.State>) -> Observable<HomeViewModel.State> {
        return state.debug("HomeViewModel", trimOutput: true)
    }
}
#endif
