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
        case select(MedicalSection)
        case add(MedicalTermType)
        case showPageBreaks
        case updateLines(indexPath: IndexPath, lines: [Line])
        case delete(IndexPath)
        case deleteAll
        case print([UIImage])
    }
    
    enum Mutation {
        case setSections([ConsultationSection])
        case setFocusedIndexPath(IndexPathWithScrollPosition)
    }
    
    struct State {
        var sections: [ConsultationSection] = []
        let terminalCellHeight: CGFloat = 40
        let pageHeight: CGFloat = 842
        var focusedIndexPath: IndexPathWithScrollPosition?
    }
    
    let initialState = State()
    
    func mutate(action: HomeViewModel.Action) -> Observable<HomeViewModel.Mutation> {
        switch action {
        case .initialLoad: return mutateInitialLoad()
        case .showPageBreaks: return mutateAddingPageBreaks()
        case let .select(medicalSection): return mutateSelectMedicalSection(medicalSection)
        case let .add(medicalTerm): return mutateAppendMedicalTerm(medicalTerm)
        case let .updateLines(indexPath, lines): return mutateUpdatingLines(at: indexPath, lines: lines)
        case let .delete(indexPath): return mutateDeleteRow(at: indexPath)
        case .deleteAll: return mutateInitialLoad()
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
        return .just(.setSections([ConsultationSection(medicalSection: medicalSection, items: [ConsultationRow(height: currentState.terminalCellHeight, lines: [Line](), medicalTerm: medicalSection.correspondingEmptyTerm)])]))
    }
    
    private func mutateAddingPageBreaks() -> Observable<Mutation> {
        return .just(.setSections(currentState.sections.removingPageBreaks().withPageBreaks(sectionHeaderHeight: 16)))
    }
    
    private func mutateSelectMedicalSection(_ medicalSection: MedicalSection) -> Observable<Mutation> {
        var sections = currentState.sections
        sections.removeAll { section in section.medicalSection != medicalSection && section.isEmpty }
        guard !sections.isEmpty, sections[0].items.count > 0, !sections[0].items[0].isTerminal else {
            let consultationRow = ConsultationRow(height: currentState.terminalCellHeight, lines: [], medicalTerm: medicalSection.correspondingEmptyTerm)
            return .just(.setSections([ConsultationSection(medicalSection: medicalSection, items: [consultationRow])]))
        }
        guard let sectionIndex = sections.firstIndex(where: { section in section.medicalSection == medicalSection }) else {
            let sectionIndex = sections.firstIndex(where: { section in section.medicalSection.printPosition > medicalSection.printPosition }) ?? sections.endIndex
            let consultationRow = ConsultationRow(height: currentState.terminalCellHeight, lines: [], medicalTerm: medicalSection.correspondingEmptyTerm)
            sections.insert(ConsultationSection(medicalSection: medicalSection, items: [consultationRow]), at: sectionIndex)
            let focusedIndexPath = IndexPathWithScrollPosition(indexPath: IndexPath(row: 0, section: sectionIndex), scrollPosition: .top)
            return .concat(.just(.setSections(sections)), .just(.setFocusedIndexPath(focusedIndexPath)))
        }
        let focusedIndexPath = IndexPathWithScrollPosition(indexPath: IndexPath(row: 0, section: sectionIndex), scrollPosition: .top)
        return .concat(.just(.setSections(sections)), .just(.setFocusedIndexPath(focusedIndexPath)))
    }
    
    private func mutateAppendMedicalTerm(_ medicalTerm: MedicalTermType) -> Observable<Mutation> {
        var sections = currentState.sections.removingPageBreaks()
        sections.removeAll { section in section.medicalSection != medicalTerm.sectionOfSelf && section.isEmpty }
        let consultationRow = ConsultationRow(height: 0, lines: [], medicalTerm: medicalTerm)
        guard !sections.isEmpty else { return .just(.setSections([ConsultationSection(medicalSection: medicalTerm.sectionOfSelf, items: [consultationRow])])) }
        guard let sectionIndex = sections.firstIndex(where: { section in section.medicalSection == medicalTerm.sectionOfSelf }) else {
            let sectionIndex = sections.firstIndex(where: { section in section.medicalSection.printPosition > medicalTerm.sectionOfSelf.printPosition }) ?? sections.endIndex
            sections.insert(ConsultationSection(medicalSection: medicalTerm.sectionOfSelf, items: []), at: sectionIndex)
            sections[sectionIndex].insert(consultationRow, with: currentState.terminalCellHeight)
            return .just(.setSections(sections))
        }
        sections[sectionIndex].insert(consultationRow, with: currentState.terminalCellHeight)
        let rowIndex = sections[sectionIndex].items.count - 1
        let focusedIndexPath = IndexPathWithScrollPosition(indexPath: IndexPath(row: rowIndex, section: sectionIndex), scrollPosition: .none)
        return .concat(.just(.setSections(sections)), .just(.setFocusedIndexPath(focusedIndexPath)))
    }

    private func mutateUpdatingLines(at indexPath: IndexPath, lines: [Line]) -> Observable<Mutation> {
        var sections = currentState.sections.removingPageBreaks()
        guard sections.count > indexPath.section, sections[indexPath.section].items.count > indexPath.row else { return .empty() }
        sections[indexPath.section].items[indexPath.row].lines = lines
        sections[indexPath.section].addTerminalCell(with: currentState.terminalCellHeight)
        return .just(.setSections(sections))
    }
    
    private func mutateDeleteRow(at indexPath: IndexPath) -> Observable<Mutation> {
        var sections = currentState.sections.removingPageBreaks()
        guard sections.count > indexPath.section, sections[indexPath.section].items.count > indexPath.row else { return .empty() }
        sections[indexPath.section].items.remove(at: indexPath.row)
        if sections.count > 1 && sections[indexPath.section].isEmpty {
            sections.remove(at: indexPath.section)
        } else {
            sections[indexPath.section].addTerminalCell(with: currentState.terminalCellHeight)
        }
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
    
    func transform(action: Observable<HomeViewModel.Action>) -> Observable<HomeViewModel.Action> {
        return action.debug("HomeViewModel", trimOutput: true)
    }
    
//    func transform(state: Observable<HomeViewModel.State>) -> Observable<HomeViewModel.State> {
//        return state.debug("HomeViewModel", trimOutput: true)
//    }
}
#endif
