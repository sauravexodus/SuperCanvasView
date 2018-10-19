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

    enum Action {
        case initialLoad
        case select(MedicalSection)
        case add(MedicalTermType, MedicalTermSection)
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
        let pageHeight: CGFloat = PageSize.selectedPage.height
        var focusedIndexPath: IndexPathWithScrollPosition?
    }
    
    let initialState = State()
    
    func mutate(action: HomeViewModel.Action) -> Observable<HomeViewModel.Mutation> {
        switch action {
        case .initialLoad: return mutateInitialLoad()
        case .showPageBreaks: return mutateAddingPageBreaks()
        case let .select(medicalSection): return mutateSelectMedicalSection(medicalSection)
        case let .add(medicalTerm, termSection): return mutateAppendMedicalTerm(medicalTerm, to: termSection)
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
        let medicalSection = MedicalSection.allSections().first(where: { section in section.isMedicalTermSection }) ?? MedicalSection(.symptoms)
        let termSection = medicalSection.medicalTermSectionValue ?? MedicalTermSection.symptoms
        let sectionIndex = MedicalSection.allSections().firstIndex(where: { section in section.isMedicalTermSection }) ?? 0
        let sections = [ConsultationSection(medicalSection: medicalSection, items: [ConsultationRow(lines: [], medicalTermSection: termSection)])]
        let focusedIndexPath = IndexPathWithScrollPosition(indexPath: IndexPath(row: 0, section: sectionIndex), scrollPosition: .top)
        return .concat(.just(.setSections(sections)), .just(.setFocusedIndexPath(focusedIndexPath)))
    }
    
    private func mutateAddingPageBreaks() -> Observable<Mutation> {
        return .just(.setSections(currentState.sections.removingPageBreaks().withPageBreaks(sectionHeaderHeight: 16)))
    }
    
    private func mutateSelectMedicalSection(_ medicalSection: MedicalSection) -> Observable<Mutation> {
        var sections = currentState.sections
        sections.removeAll { section in section.medicalSection != medicalSection && section.isEmpty }
        guard !sections.isEmpty, sections[0].items.count > 0, !sections[0].items[0].isTerminal else {
            let consultationRow = medicalSection.isMedicalTermSection ? ConsultationRow(lines: [], medicalTermSection: medicalSection.medicalTermSectionValue!) : ConsultationRow(lines: [], medicalFormSection: medicalSection.medicalFormSectionValue!)
            return .just(.setSections([ConsultationSection(medicalSection: medicalSection, items: [consultationRow])]))
        }
        guard let sectionIndex = sections.firstIndex(where: { section in section.medicalSection == medicalSection }) else {
            let sectionIndex = sections.firstIndex(where: { section in section.medicalSection.printPosition > medicalSection.printPosition }) ?? sections.endIndex
            let consultationRow = medicalSection.isMedicalTermSection ? ConsultationRow(lines: [], medicalTermSection: medicalSection.medicalTermSectionValue!) : ConsultationRow(lines: [], medicalFormSection: medicalSection.medicalFormSectionValue!)
            sections.insert(ConsultationSection(medicalSection: medicalSection, items: [consultationRow]), at: sectionIndex)
            let focusedIndexPath = IndexPathWithScrollPosition(indexPath: IndexPath(row: 0, section: sectionIndex), scrollPosition: .none)
            return .concat(.just(.setSections(sections)), .just(.setFocusedIndexPath(focusedIndexPath)))
        }
        let focusedIndexPath = IndexPathWithScrollPosition(indexPath: IndexPath(row: 0, section: sectionIndex), scrollPosition: .none)
        return .concat(.just(.setSections(sections)), .just(.setFocusedIndexPath(focusedIndexPath)))
    }
    
    private func mutateAppendMedicalTerm(_ medicalTerm: MedicalTermType, to termSection: MedicalTermSection) -> Observable<Mutation> {
        var sections = currentState.sections.removingPageBreaks()
        sections.removeAll { section in
            guard let medicalTermSection = section.medicalSection.medicalTermSectionValue else {
                return section.isEmpty
            }
            return medicalTermSection != termSection && section.isEmpty
        }
        let consultationRow = ConsultationRow(lines: [], medicalTermSection: termSection, medicalTerm: medicalTerm)
        guard !sections.isEmpty else { return .just(.setSections([ConsultationSection(medicalSection: MedicalSection(termSection), items: [consultationRow])])) }
        guard let sectionIndex = sections.firstIndex(where: { section in section.medicalSection == MedicalSection(termSection) }) else {
            let sectionIndex = sections.firstIndex(where: { section in section.medicalSection.printPosition > MedicalSection(termSection).printPosition }) ?? sections.endIndex
            sections.insert(ConsultationSection(medicalSection: MedicalSection(termSection), items: []), at: sectionIndex)
            sections[sectionIndex].insert(consultationRow)
            return .just(.setSections(sections))
        }
        sections[sectionIndex].insert(consultationRow)
        let rowIndex = sections[sectionIndex].items.count - 1
        let focusedIndexPath = IndexPathWithScrollPosition(indexPath: IndexPath(row: rowIndex, section: sectionIndex), scrollPosition: .none)
        return .concat(.just(.setSections(sections)), .just(.setFocusedIndexPath(focusedIndexPath)))
    }

    private func mutateUpdatingLines(at indexPath: IndexPath, lines: [Line]) -> Observable<Mutation> {
        var sections = currentState.sections.removingPageBreaks()
        guard sections.count > indexPath.section, sections[indexPath.section].items.count > indexPath.row else { return .empty() }
        sections[indexPath.section].items[indexPath.row].lines = lines
        sections[indexPath.section].addTerminalCell()
        return .just(.setSections(sections))
    }
    
    private func mutateDeleteRow(at indexPath: IndexPath) -> Observable<Mutation> {
        var sections = currentState.sections.removingPageBreaks()
        guard sections.count > indexPath.section, sections[indexPath.section].items.count > indexPath.row else { return .empty() }
        sections[indexPath.section].items.remove(at: indexPath.row)
        if sections.count > 1 && sections[indexPath.section].isEmpty {
            sections.remove(at: indexPath.section)
        } else {
            sections[indexPath.section].addTerminalCell()
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
}
#endif
